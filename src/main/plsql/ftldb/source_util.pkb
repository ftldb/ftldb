--
-- Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

create or replace package body source_util as


-- Blank characters: space and tab.
gc_blank constant varchar2(2) := ' ' || chr(9);

-- LF character (*nix EOL).
gc_lf constant varchar2(1) := chr(10);

-- CRLF characters (Win EOL).
gc_crlf constant varchar2(2) := chr(13) || chr(10);

-- EOL pattern: LF or CRLF.
gc_eol constant varchar2(6) := '(' || gc_lf || '|' || gc_crlf || ')';


-- The regexp pattern for the beginning of a non-compiled section.
gc_noncmp_section_start_ptrn constant varchar2(128) :=
  '\$if\s+(false|null)\s+\$then[' || gc_blank || ']*' || gc_eol || '?';

-- The regexp pattern for the ending of a non-compiled section.
gc_noncmp_section_end_ptrn constant varchar2(128) :=
  '[' || gc_blank || ']*\$end';

-- The regexp pattern for the beginning of a named section. The %name%
-- placeholder should be replaced with the section name.
gc_named_section_start_ptrn constant varchar2(128) :=
  '[' || gc_blank || ']*(--|//|#)[' || gc_blank || ']*%begin' ||
  '[' || gc_blank || ']+' || '%name%' ||
  '([' || gc_blank || '][^' || gc_crlf || ']*)?' || gc_eol;

-- The regexp pattern for the ending of a named section. The %name%
-- placeholder should be replaced with the section name.
gc_named_section_end_ptrn constant varchar2(128) :=
  '[' || gc_blank || ']*(--|//|#)[' || gc_blank || ']*%end' ||
  '[' || gc_blank || ']+' || '%name%' ||
  '([' || gc_blank || '][^' || gc_crlf || ']*)?' || gc_eol;


function long2clob(
  in_sql in varchar2,
  in_vars in varchar2_nt := varchar2_nt(),
  in_vals in varchar2_nt := varchar2_nt()
) return clob
is
  l_cur integer;
  l_col_count pls_integer;
  l_col_desc_tab dbms_sql.desc_tab;
  l_offset pls_integer := 0;
  l_row_cnt pls_integer;
  c_piece_size constant pls_integer := 32767;
  l_piece varchar2(32767);
  l_piece_len pls_integer;
  l_clob clob;
  c_long_type constant pls_integer :=
    $if dbms_db_version.version < 11 $then 8 $else dbms_sql.long_type $end ;
begin
  -- Validate the input collections.
  case
    when in_vars is null or nvl(in_vars.last(), 0) != in_vars.count() then
      raise_application_error(
        gc_invalid_argument_num,
        'collection in_vars is uninitialized or sparse'
      );
    when in_vals is null or nvl(in_vals.last(), 0) != in_vals.count() then
      raise_application_error(
        gc_invalid_argument_num,
        'collection in_vals is uninitialized or sparse'
      );
    when in_vars.count() != in_vals.count() then
      raise_application_error(
        gc_invalid_argument_num,
        'collections in_vars and in_vals do not match'
      );
    else null;
  end case;

  l_cur := dbms_sql.open_cursor();
  dbms_sql.parse(l_cur, in_sql, dbms_sql.native);
  dbms_sql.describe_columns(l_cur, l_col_count, l_col_desc_tab);

  -- Check that the query returns a single long column.
  if l_col_count > 1 or l_col_desc_tab(1).col_type != c_long_type then
    raise_application_error(
      gc_invalid_argument_num,
      'query does not return a single LONG column'
    );
  end if;

  for l_i in 1..in_vars.count() loop
    dbms_sql.bind_variable(l_cur, in_vars(l_i), in_vals(l_i));
  end loop;
  dbms_sql.define_column_long(l_cur, 1);
  l_row_cnt := dbms_sql.execute_and_fetch(l_cur);

  -- Check that the query returns at least one row.
  if l_row_cnt = 0 then
    raise no_data_found;
  end if;

  l_clob := clob_util.create_temporary();
  loop
    dbms_sql.column_value_long(
      l_cur, 1, c_piece_size, l_offset, l_piece, l_piece_len
    );
    clob_util.put(l_clob, l_piece);
    l_offset := l_offset + c_piece_size;
    exit when l_piece_len < c_piece_size;
  end loop;

  -- Check that the query returns not more than one row.
  l_row_cnt := dbms_sql.fetch_rows(l_cur);
  if l_row_cnt > 0 then
    raise too_many_rows;
  end if;

  dbms_sql.close_cursor(l_cur);
  return l_clob;
exception
  when others then
    if dbms_sql.is_open(l_cur) then
      dbms_sql.close_cursor(l_cur);
    end if;
    raise;
end long2clob;


/**
 * Quotes the given name.
 */
function q(in_name in varchar2) return varchar2
is
begin
  return '"' || in_name || '"';
end q;


/**
 * Quotes the given dblink and prefixes @ to it.
 */
function a(in_dblink in varchar2) return varchar2
is
begin
  return case when in_dblink is not null then '@' || q(in_dblink) end;
end a;


/**
 * Validates an Oracle name and splits it into 3 parts.
 */
procedure tokenize_ora_name(
  in_ora_name in varchar2,
  out_owner out varchar2,
  out_obj_name out varchar2,
  out_dblink out varchar2
)
is
  l_a varchar2(30);
  l_b varchar2(30);
  l_c varchar2(30);
  l_dblink varchar2(128);
  l_nextpos pls_integer;
begin
  begin
    dbms_utility.name_tokenize(
      in_ora_name, l_a, l_b, l_c, l_dblink, l_nextpos
    );
  exception
    when others then
      raise_application_error(
        gc_invalid_argument_num,
        'failed to parse Oracle name ' || in_ora_name || ': ' ||
        regexp_replace(sqlerrm, 'ORA-\d+: ')
      );
  end;

  if l_c is not null then
    raise_application_error(
      gc_invalid_argument_num,
      'failed to parse Oracle name ' || in_ora_name || ': ' ||
      'subprograms are not supported'
    );
  end if;

  if l_b is not null then
    out_owner := l_a;
    out_obj_name := l_b;
  else
    out_obj_name := l_a;
  end if;

  out_dblink := l_dblink;
end tokenize_ora_name;


/**
 * Concatenates an Oracle name from parts.
 */
function concat_ora_name(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2 := null,
  in_type in varchar2 := null
) return varchar2
is
begin
  return
    case when in_owner is not null then q(in_owner) || '.' end ||
    q(in_obj_name) ||
    a(in_dblink) ||
    case when in_type is not null then ' (' || upper(in_type) || ')' end;
end concat_ora_name;


/**
 * Resolves a tokenized Oracle name with the native resolver.
 */
function resolve_ora_name_with_natrslvr(
  io_owner in out varchar2,
  io_obj_name in out varchar2,
  io_dblink in out varchar2,
  out_type out varchar2
) return boolean
is
  l_local_name varchar2(70) := concat_ora_name(io_owner, io_obj_name);

  e_incompatible_context exception;
  pragma exception_init(e_incompatible_context, -4047);

  e_object_not_exist exception;
  pragma exception_init(e_object_not_exist, -6564);

  -- Supported values for the context flag (from most to least possible).
  c_supported_ctx_values constant number_nt :=
    number_nt(
      1 /*function, procedure, package*/, 2 /*view*/, 7 /*type*/,
      3 /*trigger*/, 4 /*java source*/, 5 /*java resource*/
    );
  l_i pls_integer;

  l_owner varchar2(30);
  l_part1 varchar2(30);
  l_part2 varchar2(30);
  l_dblink varchar2(128);
  l_part1_type number;
  l_obj_num number;

begin
  l_i := c_supported_ctx_values.first();

  while l_i is not null loop
    begin
      execute immediate
        'begin dbms_utility.name_resolve' || a(io_dblink) ||
        '(:1, :2, :3, :4, :5, :6, :7, :8); end;'
      using
        in l_local_name, in c_supported_ctx_values(l_i), out l_owner,
        out l_part1, out l_part2, out l_dblink, out l_part1_type, out l_obj_num;

      exit;
    exception
      when e_incompatible_context or e_object_not_exist then
        l_i := c_supported_ctx_values.next(l_i);
    end;
  end loop;

  if l_i is null then
    return false;
  end if;

  if l_dblink is not null then
    if io_dblink is not null then
      raise_application_error(
        gc_name_not_resolved_num,
        utl_lms.format_message(
          gc_dblink_over_dblink_msg, l_local_name || a(io_dblink), l_dblink
        )
      );
    end if;
    io_dblink := l_dblink;
  end if;

  if l_part1 is not null and l_part2 is not null then
    return false;
  end if;

  out_type :=
    case l_part1_type
      when 8 then 'FUNCTION'
      when 7 then 'PROCEDURE'
      when 9 then 'PACKAGE'
      when 4 then 'VIEW'
      when 13 then 'TYPE'
      when 12 then 'TRIGGER'
      when 28 then 'JAVA SOURCE'
      when 30 then 'JAVA RESOURCE'
    end;

  io_obj_name := coalesce(l_part1, l_part2);
  io_owner := l_owner;

  return true;
end resolve_ora_name_with_natrslvr;


/**
 * Resolves a tokenized Oracle name with direct queries to the data dictionary.
 */
function resolve_ora_name_with_datadict(
  io_owner in out varchar2,
  io_obj_name in out varchar2,
  io_dblink in out varchar2,
  out_type out varchar2
) return boolean
is
  -- The bag of the recursively found synonyms, protects against looping chains.
  type number_ht is table of number index by varchar2(190);
  l_bag number_ht;

  c_user_users_query constant varchar2(32767) :=
    'select u.username from user_users%dblink% u';

  c_all_objects_query constant varchar2(32767) :=
    'select o.object_type' || gc_lf ||
    'from all_objects%dblink% o' || gc_lf ||
    'where' || gc_lf ||
    '  o.owner = :owner and' || gc_lf ||
    '  o.object_name = :name and' || gc_lf ||
    '  o.object_type in (select value(t) from table(:types) t)';

  c_all_synonyms_query constant varchar2(32767) :=
    'select' || gc_lf ||
    '  max(s.owner) keep (dense_rank first order by' || gc_lf ||
    '       decode(s.owner, ''PUBLIC'', 2, 1)),' || gc_lf ||
    '  max(s.table_owner) keep (dense_rank first order by' || gc_lf ||
    '       decode(s.owner, ''PUBLIC'', 2, 1)),' || gc_lf ||
    '  max(s.table_name) keep (dense_rank first order by' || gc_lf ||
    '       decode(s.owner, ''PUBLIC'', 2, 1)),' || gc_lf ||
    '  max(s.db_link) keep (dense_rank first order by' || gc_lf ||
    '       decode(s.owner, ''PUBLIC'', 2, 1))' || gc_lf ||
    'from all_synonyms%dblink% s' || gc_lf ||
    'where' || gc_lf ||
    '  s.owner in (:owner, ''PUBLIC'') and' || gc_lf ||
    '  s.synonym_name = :name' || gc_lf ||
    'group by null';

  function recur_resolve_with_datadict(
    io_owner in out varchar2,
    io_obj_name in out varchar2,
    io_dblink in out varchar2,
    out_type out varchar2
  ) return boolean
  is
    l_syn_full_name varchar2(190);
    l_syn_owner varchar2(30);
    l_ref_owner varchar2(30);
    l_ref_name varchar2(30);
    l_ref_dblink varchar2(128);
  begin
    -- Determine the name's owner, if omitted.
    if io_owner is null then
      -- If it's a local name, the owner is the current schema.
      if io_dblink is null then
        io_owner := sys_context('userenv', 'current_schema');
      else
      -- If it's a remote name, the owner is the connecting schema.
        execute immediate replace(c_user_users_query, '%dblink%', a(io_dblink))
        into io_owner;
      end if;
    end if;

    -- Try to find the object and its type.
    begin
      execute immediate replace(c_all_objects_query, '%dblink%', a(io_dblink))
      into out_type
      using in io_owner, in io_obj_name, in gc_supported_obj_types;

      return true;
    exception
      when no_data_found then
        null;
    end;

    -- The name may be a synonym (private or public), try to resolve it.
    begin
      execute immediate replace(c_all_synonyms_query, '%dblink%', a(io_dblink))
      into l_syn_owner, l_ref_owner, l_ref_name, l_ref_dblink
      using in io_owner, in io_obj_name;
    exception
      when no_data_found then
        return false;
    end;

    l_syn_full_name := concat_ora_name(l_syn_owner, io_obj_name, io_dblink);

    -- If a looping chain is detected, the synonym cannot be resolved.
    if l_bag.exists(l_syn_full_name) then
      raise_application_error(
        gc_name_not_resolved_num,
        utl_lms.format_message(gc_looping_synonym_chain_msg, l_syn_full_name)
      );
    end if;

    -- Save the current synonym's full name to a bag.
    l_bag(l_syn_full_name) := 1;

    -- Set the referenced object's attributes.
    io_owner := l_ref_owner;
    io_obj_name := l_ref_name;

    -- If the synonym references to a remote object...
    if l_ref_dblink is not null then
      -- If the synonym is itself remote and hence references to a remote
      -- object on a different DB, exit with failure (too complex to resolve).
      if io_dblink is not null then
        raise_application_error(
          gc_name_not_resolved_num,
          utl_lms.format_message(
            gc_dblink_over_dblink_msg, l_syn_full_name, q(l_ref_dblink)
          )
        );
      -- Otherwise set the dblink.
      else
        io_dblink := l_ref_dblink;
      end if;
    end if;

    -- Try to resolve the referenced synonym.
    return
      recur_resolve_with_datadict(
        io_owner, io_obj_name, io_dblink, out_type
      );
  end recur_resolve_with_datadict;

begin
  return
    recur_resolve_with_datadict(io_owner, io_obj_name, io_dblink, out_type);
end resolve_ora_name_with_datadict;


procedure resolve_ora_name(
  in_ora_name in varchar2,
  out_owner out varchar2,
  out_obj_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
)
is
begin
  -- Tokenize the name into parts.
  tokenize_ora_name(in_ora_name, out_owner, out_obj_name, out_dblink);

  -- Try to resolve name with the native Oracle resolver, then with the custom.
  if
    not resolve_ora_name_with_natrslvr(
      out_owner, out_obj_name, out_dblink, out_type
    )
  and
    not resolve_ora_name_with_datadict(
      out_owner, out_obj_name, out_dblink, out_type
    )
  then
    raise_application_error(
      gc_name_not_resolved_num,
      utl_lms.format_message(gc_name_not_resolved_msg, in_ora_name)
    );
  end if;
end resolve_ora_name;


/**
 * Splits the full template name into a container name and a section name.
 */
procedure split_src_name(
  in_src_name in varchar2,
  out_container_name out varchar2,
  out_section_name out varchar2
)
is
  c_simple_name constant varchar2(32) := '[A-Za-z][0-9A-Za-z_$#]{0,29}';
  c_quoted_name constant varchar2(32) := '"[^"]{1,30}"';
  c_any_name constant varchar2(70) := c_simple_name || '|' || c_quoted_name;
  c_src_name_ptrn constant varchar2(300) :=
    '^\s*' ||
    '(' || c_any_name || ')' || --\1
    '(\s*\.\s*(' || c_any_name ||'))?' || --\2 \3
    '(\s*%\s*(' || c_simple_name ||'))?' || --\4 \5
    '(\s*@\s*(' || c_any_name || '))?' || --\6 \7
    '\s*$';
begin
  if not nvl(regexp_like(in_src_name, c_src_name_ptrn), false) then
    raise_application_error(
      gc_invalid_argument_num,
      'failed to parse template name ' || in_src_name
    );
  end if;

  out_container_name :=
    regexp_replace(in_src_name, c_src_name_ptrn, '\1\2\6');
  out_section_name :=
    regexp_replace(in_src_name, c_src_name_ptrn, '\5');
end split_src_name;


procedure resolve_src_name(
  in_src_name in varchar2,
  out_owner out varchar2,
  out_obj_name out varchar2,
  out_sec_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
)
is
  l_container_name varchar2(4000);
begin
  split_src_name(in_src_name, l_container_name, out_sec_name);
  resolve_ora_name(
    l_container_name, out_owner, out_obj_name, out_dblink, out_type
  );
end resolve_src_name;


/**
 * Shortens long names that are not presented in the JAVASNM dictionary view.
 */
function gen_short_name(in_long_name varchar2) return varchar2
is
  l_prefix varchar2(10);
begin
  if
    in_long_name is null or
    instr(in_long_name, chr(0)) > 0 or
    instr(in_long_name, '"') > 0 or
    length(in_long_name) > 4000
  then
    raise value_error;
  end if;

  if length(in_long_name) <= 30 then
    return in_long_name;
  end if;
  
  select '/' || lower(to_char(ora_hash(in_long_name), 'fmxxxxxxxx')) || '_'
  into l_prefix
  from dual;
  
  return 
    l_prefix ||
    substr(
      regexp_replace(
        substr(in_long_name, instr(in_long_name, '/', -1)), '[^0-9A-Za-z_]'
      ),
      1, 30 - length(l_prefix)
    );
end gen_short_name;


function short_name(in_long_name in varchar2) return varchar2
is
begin
  return
    coalesce(dbms_java.shortname(in_long_name), gen_short_name(in_long_name));
end short_name;


procedure resolve_long_name(
  in_long_name in varchar2,
  out_owner out varchar2,
  out_obj_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
)
is
begin
  resolve_ora_name(
    q(short_name(in_long_name)), out_owner, out_obj_name, out_dblink, out_type
  );
end resolve_long_name;


function get_obj_timestamp(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return timestamp
is
  c_type constant varchar2(30) := upper(in_type);
  -- ALL_OBJECTS returns the TIMESTAMP column as a string
  c_all_objects_query constant varchar2(32767) :=
    'select' || gc_lf ||
    '  max(to_timestamp(o.timestamp, ''yyyy-mm-dd:hh24:mi:ss''))' || gc_lf ||
    'from all_objects%dblink% o' || gc_lf ||
    'where' || gc_lf ||
    '  o.owner = :owner and' || gc_lf ||
    '  o.object_name = :name and' || gc_lf ||
    '  o.object_type in (:type, :type || '' BODY'')' || gc_lf ||
    'group by null';
  l_timestamp timestamp;
begin
  -- Check the input argument values.
  case
    when in_owner is null then
      raise_application_error(
        gc_invalid_argument_num, 'object owner is not specified'
      );
    when in_obj_name is null then
      raise_application_error(
        gc_invalid_argument_num, 'object name is not specified'
      );
    when c_type is null then
      raise_application_error(
        gc_invalid_argument_num, 'object type is not specified'
      );
    when not c_type member of gc_supported_obj_types then
      raise_application_error(
        gc_invalid_argument_num,
        'object type ' || c_type || ' is not supported'
      );
    else null;
  end case;

  execute immediate
    replace(c_all_objects_query, '%dblink%', a(in_dblink))
  into l_timestamp
  using in_owner, in_obj_name, c_type, c_type;

  return l_timestamp;
exception
  when no_data_found then
    raise_application_error(
      gc_object_not_found_num,
      utl_lms.format_message(
        gc_object_not_found_msg,
        concat_ora_name(in_owner, in_obj_name, in_dblink), c_type
      )
    );
end get_obj_timestamp;


function get_view_source(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2
) return clob
is
  c_all_views_query constant varchar2(32767) :=
    'select v.text' || gc_lf ||
    'from all_views%dblink% v' || gc_lf ||
    'where' || gc_lf ||
    '  v.owner = :owner and' || gc_lf ||
    '  v.view_name = :name';
begin
  return
    long2clob(
      replace(c_all_views_query, '%dblink%', a(in_dblink)),
      varchar2_nt(':owner', ':name'), varchar2_nt(in_owner, in_obj_name)
    );
end get_view_source;


function get_java_resource(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2
) return clob
is
  l_clob clob := clob_util.create_temporary();
begin
  if in_dblink is not null then
    raise_application_error(
      gc_invalid_argument_num,
      'loading Java resources over dblink is not supported'
    );
  end if;

  begin
    dbms_java.export_resource(in_obj_name, in_owner, l_clob);
  exception
    when others then
      if sqlerrm like '%no such java schema object%' then
        raise no_data_found;
      else
        raise;
      end if;
  end;

  return l_clob;
end get_java_resource;


function get_program_unit_source(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return clob
is
  c_all_source_query constant varchar2(32767) :=
    'select s.text' || gc_lf ||
    'from all_source%dblink% s' || gc_lf ||
    'where' || gc_lf ||
    '  s.owner = :owner and' || gc_lf ||
    '  s.name = :name and' || gc_lf ||
    '  s.type in (:type, :type || '' BODY'')' || gc_lf ||
    'order by s.type, s.line';
  c_eol constant varchar2(1) :=
    case when in_type = 'JAVA SOURCE' then gc_lf end;
  l_src_lines dbms_sql.varchar2a;
  l_src clob;
begin
  execute immediate
    replace(c_all_source_query, '%dblink%', a(in_dblink))
  bulk collect into l_src_lines
  using in_owner, in_obj_name, in_type, in_type;

  -- Check that the source is found.
  if l_src_lines.count() = 0 then
    raise no_data_found;
  end if;

  l_src := clob_util.create_temporary();
  for l_i in 1..l_src_lines.count() loop
    clob_util.put(l_src, l_src_lines(l_i) || c_eol);
  end loop;

  return l_src;
end get_program_unit_source;


function get_obj_source(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return clob
is
  c_type constant varchar2(30) := upper(in_type);
begin
  -- Check the input argument values.
  case
    when in_owner is null then
      raise_application_error(
        gc_invalid_argument_num, 'object owner is not specified'
      );
    when in_obj_name is null then
      raise_application_error(
        gc_invalid_argument_num, 'object name is not specified'
      );
    when c_type is null then
      raise_application_error(
        gc_invalid_argument_num, 'object type is not specified'
      );
    when not c_type member of gc_supported_obj_types then
      raise_application_error(
        gc_invalid_argument_num,
        'object type ' || c_type || ' is not supported'
      );
    else null;
  end case;

  return
    case
      when c_type = 'VIEW' then
        get_view_source(in_owner, in_obj_name, in_dblink)
      when c_type = 'JAVA RESOURCE' then
        get_java_resource(in_owner, in_obj_name, in_dblink)
      else
        get_program_unit_source(in_owner, in_obj_name, in_dblink, c_type)
    end;

exception
  when no_data_found then
    raise_application_error(
      gc_source_not_found_num,
      utl_lms.format_message(
        gc_source_not_found_msg,
        concat_ora_name(in_owner, in_obj_name, in_dblink), c_type
      )
    );
end get_obj_source;


function extract_section_from_clob(
  in_container in clob,
  in_start_pattern in varchar2,
  in_end_pattern in varchar2,
  in_keep_boundaries in boolean := false,
  in_lazy_search in boolean := false,
  in_occurrence in positiven := 1
) return clob
is
  l_res clob;
begin
  -- Check the argument values.
  if not nvl(in_lazy_search, false) and in_occurrence > 1  then
    raise_application_error(
      gc_invalid_argument_num,
      'occurrence cannot be specified for greedy search'
    );
  end if;

  l_res := regexp_substr(
    in_container,
    in_start_pattern || '.*' || case when in_lazy_search then '?' end ||
      in_end_pattern,
    1, in_occurrence, 'in'
  );

  if nvl(dbms_lob.getlength(l_res), 0) = 0 then
    raise_application_error(
      gc_section_not_found_num,
      utl_lms.format_message(
        gc_section_not_found_msg, in_occurrence,
        in_start_pattern, in_end_pattern, 'in_container'
      )
    );
  end if;

  if not nvl(in_keep_boundaries, false) then
    l_res := regexp_replace(
      regexp_replace(
        l_res, '^' || in_start_pattern, '', 1, 1, 'in'
      ),
      in_end_pattern || '$', '', 1, 1, 'in'
    );
  end if;

  return l_res;

end extract_section_from_clob;


function extract_section_from_obj_src(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2,
  in_start_ptrn in varchar2,
  in_end_ptrn in varchar2,
  in_keep_boundaries in boolean := false,
  in_lazy_search in boolean := false,
  in_occurrence in positiven := 1
) return clob
is
begin
  return
    extract_section_from_clob(
      get_obj_source(in_owner, in_obj_name, in_dblink, in_type),
      in_start_ptrn, in_end_ptrn, in_keep_boundaries,
      in_lazy_search, in_occurrence
    );
exception
  when e_section_not_found then
    raise_application_error(
      gc_section_not_found_num,
      utl_lms.format_message(
        gc_section_not_found_msg, in_occurrence,
        in_start_ptrn, in_end_ptrn,
        concat_ora_name(in_owner, in_obj_name, in_dblink, in_type)
      )
    );
end extract_section_from_obj_src;


function extract_section_from_obj_src(
  in_container_name in varchar2,
  in_start_ptrn in varchar2,
  in_end_ptrn in varchar2,
  in_keep_boundaries in boolean := false,
  in_lazy_search in boolean := false,
  in_occurrence in positiven := 1
) return clob
is
  l_owner varchar2(30);
  l_obj_name varchar2(30);
  l_dblink varchar2(128);
  l_type varchar2(30);
begin
  resolve_ora_name(in_container_name, l_owner, l_obj_name, l_dblink, l_type);

  return
    extract_section_from_obj_src(
      l_owner, l_obj_name, l_dblink, l_type,
      in_start_ptrn, in_end_ptrn, in_keep_boundaries,
      in_lazy_search, in_occurrence
    );
end extract_section_from_obj_src;


function extract_noncompiled_section(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return clob
is
begin
  return
    extract_section_from_obj_src(
      in_owner, in_obj_name, in_dblink, in_type,
      gc_noncmp_section_start_ptrn, gc_noncmp_section_end_ptrn
    );
exception
  when e_section_not_found then
    raise_application_error(
      gc_section_not_found_num,
      utl_lms.format_message(
        gc_ncmp_section_not_found_msg,
        concat_ora_name(in_owner, in_obj_name, in_dblink, in_type)
      )
    );
end extract_noncompiled_section;


function extract_noncompiled_section(in_container_name in varchar2) return clob
is
  l_owner varchar2(30);
  l_obj_name varchar2(30);
  l_dblink varchar2(128);
  l_type varchar2(30);
begin
  resolve_ora_name(in_container_name, l_owner, l_obj_name, l_dblink, l_type);

  return extract_noncompiled_section(l_owner, l_obj_name, l_dblink, l_type);
end extract_noncompiled_section;


function escape_section_name(
  in_section_name in varchar2
) return varchar2
is
begin
  if
    not nvl(
      regexp_like(in_section_name, '^[A-Za-z][0-9A-Za-z_$#]{0,29}$'), false
    )
  then
    raise_application_error(
      gc_invalid_argument_num,
      'section name ' || in_section_name || ' is not valid'
    );
  end if;
  return replace(in_section_name, '$', '\$');
end escape_section_name;


function extract_named_section(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2,
  in_section_name in varchar2,
  in_occurrence in positiven := 1
) return clob
is
  c_section_name constant varchar2(60) := escape_section_name(in_section_name);
begin
  return
    extract_section_from_obj_src(
      in_owner, in_obj_name, in_dblink, in_type,
      replace(gc_named_section_start_ptrn, '%name%', c_section_name),
      replace(gc_named_section_end_ptrn, '%name%', c_section_name),
      false, true, in_occurrence
    );
exception
  when e_section_not_found then
    raise_application_error(
      gc_section_not_found_num,
      utl_lms.format_message(
        gc_named_section_not_found_msg, in_occurrence, in_section_name,
        concat_ora_name(in_owner, in_obj_name, in_dblink, in_type)
      )
    );
end extract_named_section;


function extract_named_section(
  in_container_name in varchar2,
  in_section_name in varchar2,
  in_occurrence in positiven := 1
) return clob
is
  l_owner varchar2(30);
  l_obj_name varchar2(30);
  l_dblink varchar2(128);
  l_type varchar2(30);
begin
  resolve_ora_name(in_container_name, l_owner, l_obj_name, l_dblink, l_type);

  return
    extract_named_section(
      l_owner, l_obj_name, l_dblink, l_type, in_section_name, in_occurrence
    );
end extract_named_section;


function replace_section_in_clob(
  in_container in clob,
  in_start_ptrn in varchar2,
  in_end_ptrn in varchar2,
  in_replacement in clob,
  in_keep_boundaries in boolean := false,
  in_lazy_search in boolean := false,
  in_occurrence in positiven := 1
) return clob
is
  l_start_pos integer;
  l_end_pos integer;
  l_prev_end_pos integer := 0;
  l_offset integer := 1;
  l_amount integer;
  l_res clob := clob_util.create_temporary();

  procedure assert_pos(in_pos pls_integer)
  is
  begin
    if not nvl(in_pos > 0, false) then
      raise_application_error(
        gc_section_not_found_num,
        utl_lms.format_message(
          gc_section_not_found_msg, in_occurrence,
          in_start_ptrn, in_end_ptrn, 'in_container'
        )
      );
    end if;
  end;

begin
  -- Check the argument values.
  if not nvl(in_lazy_search, false) and in_occurrence > 1 then
    raise_application_error(
      gc_invalid_argument_num,
      'occurrence cannot be specified for greedy search'
    );
  end if;

  if in_lazy_search then
    l_start_pos :=
      regexp_instr(
        in_container, in_start_ptrn, 1, in_occurrence,
        case when in_keep_boundaries then 1 else 0 end, 'in'
      );
    assert_pos(l_start_pos);

    l_end_pos :=
      regexp_instr(
        in_container, in_end_ptrn, 1, in_occurrence,
        case when in_keep_boundaries then 0 else 1 end, 'in'
      );
    assert_pos(l_end_pos);

  else
    l_start_pos :=
      regexp_instr(
        in_container, in_start_ptrn, 1, 1,
        case when in_keep_boundaries then 1 else 0 end, 'in'
      );
    assert_pos(l_start_pos);

    if in_keep_boundaries then
      loop
        l_end_pos :=
          regexp_instr(in_container, in_end_ptrn, l_offset, 1, 0, 'in');
        exit when l_end_pos = 0;
        l_offset :=
          regexp_instr(in_container, in_end_ptrn, l_offset, 1, 1, 'in');
        l_prev_end_pos := l_end_pos;
      end loop;

      l_end_pos := l_prev_end_pos;
      assert_pos(l_end_pos);

    else
      l_end_pos :=
        regexp_instr(in_container, '^.*' || in_end_ptrn, 1, 1, 1, 'in');
      assert_pos(l_end_pos);

    end if;
  end if;

  -- Copy preceding part
  l_amount := l_start_pos - 1;
  if l_amount > 0 then
    dbms_lob.copy(l_res, in_container, l_amount);
  end if;

  -- Copy replacement
  dbms_lob.append(l_res, in_replacement);

  -- Copy following part
  l_amount := dbms_lob.getlength(in_container) - l_end_pos + 1;
  if l_amount > 0 then
    dbms_lob.copy(
      l_res, in_container, l_amount, dbms_lob.getlength(l_res) + 1, l_end_pos
     );
  end if;

  return l_res;
end replace_section_in_clob;


function replace_named_section_in_clob(
  in_container clob,
  in_section_name varchar2,
  in_replacement clob,
  in_keep_boundaries in boolean := false,
  in_occurrence in positiven := 1
) return clob
is
  c_section_name constant varchar2(60) := escape_section_name(in_section_name);
begin
  return
    replace_section_in_clob(
      in_container,
      replace(gc_named_section_start_ptrn, '%name%', c_section_name),
      replace(gc_named_section_end_ptrn, '%name%', c_section_name),
      in_replacement, in_keep_boundaries, true, in_occurrence
    );
exception
  when e_section_not_found then
    raise_application_error(
      gc_section_not_found_num,
      utl_lms.format_message(
        gc_named_section_not_found_msg, in_occurrence,
        in_section_name, 'in_container'
      )
    );
end replace_named_section_in_clob;


end source_util;
/
