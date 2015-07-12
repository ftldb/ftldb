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

-- The regexp pattern for the beginning of a non-compiled section. Used in
-- {%link extract_noncompiled_section}.
gc_noncmp_section_start_ptrn constant varchar2(128) :=
  '\$if[[:space:]]+(false|null)[[:space:]]+\$then[[:blank:]]*' ||
  chr(10) || '?';

-- The regexp pattern for the ending of a non-compiled section. Used in
-- {%link extract_noncompiled_section}.
gc_noncmp_section_end_ptrn constant varchar2(128) :=
  '[[:blank:]]*\$end';

-- The regexp pattern for the beginning of a named section. The %name%
-- placeholder should be replaced with the section name. Used in
-- {%link extract_named_section}, {%link replace_named_section_in_clob}.
gc_named_section_start_ptrn constant varchar2(128) :=
  '[[:blank:]]*--[[:blank:]]*%begin[[:blank:]]+' || '%name%' ||
  '([[:blank:]][^' || chr(10) || ']*)?' || chr(10);

-- The regexp pattern for the ending of a named section. The %name%
-- placeholder should be replaced with the section name. Used in
-- {%link extract_named_section}, {%link replace_named_section_in_clob}.
gc_named_section_end_ptrn constant varchar2(128) :=
  '[[:blank:]]*--[[:blank:]]*%end[[:blank:]]+' || '%name%' ||
  '([[:blank:]][^' || chr(10) || ']*)?' || chr(10);


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
 * Prefixes '@' to the given dblink.
 */
function a(in_dblink in varchar2) return varchar2
is
begin
  return case when in_dblink is not null then '@' || in_dblink end;
end a;


/**
 * Returns Oracle object's full name and type.
 */
function full_name(
  in_owner in varchar2,
  in_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return varchar2
is
begin
  return
    case
      when in_owner = upper(in_owner) then in_owner
      else '"' || in_owner || '"'
    end ||
    '.' ||
    case
      when in_name = upper(in_name) then in_name
      else '"' || in_name || '"'
    end ||
    a(in_dblink) ||
    ' (' || in_type || ')';
end full_name;


function try_to_resolve_ora_name(
  in_local_name in varchar2,
  in_dblink in varchar2,
  out_owner out varchar2,
  out_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
) return boolean
is
  e_incompatible_context exception;
  pragma exception_init(e_incompatible_context, -4047);

  e_object_not_exist exception;
  pragma exception_init(e_object_not_exist, -6564);

  -- Supported values for the context flag (from most to least possible).
  c_supported_ctx_values constant number_nt :=
    number_nt(
      1 /*function, procedure, package*/, 2 /*view*/, 7 /*type*/,
      3 /*trigger*/, 4 /*java source*/
    );
  l_i pls_integer;

  procedure resolved(in_type in varchar2, in_name in varchar2)
  is
  begin
    out_type := in_type;
    out_name := in_name;
  end resolved;

  function try_to_resolve_ora_name_by_ctx(in_context number) return boolean
  is
    l_part1 varchar2(30);
    l_part2 varchar2(30);
    l_part1_type number;
    l_obj_num number;
  begin
    execute immediate
      'call dbms_utility.name_resolve' || a(in_dblink) ||
      '(:1, :2, :3, :4, :5, :6, :7, :8)'
    using
      in in_local_name, in in_context, out out_owner, out l_part1,
      out l_part2, out out_dblink, out l_part1_type, out l_obj_num;

    if in_dblink is not null and out_dblink is null then
      out_dblink := in_dblink;
    end if;

    case l_part1_type
      when 8 then resolved('FUNCTION', l_part2);
      when 7 then resolved('PROCEDURE', l_part2);
      when 9 then
        if l_part2 is not null then
          return false;
        end if;
        resolved('PACKAGE', l_part1);
      when 4 then resolved('VIEW', l_part1);
      when 13 then resolved('TYPE', l_part1);
      when 12 then resolved('TRIGGER', l_part1);
      when 28 then resolved('JAVA SOURCE', l_part1);
      else return false;
    end case;

    return true;
  end try_to_resolve_ora_name_by_ctx;

begin
  l_i := c_supported_ctx_values.first();
  while l_i is not null loop
    begin
      return try_to_resolve_ora_name_by_ctx(c_supported_ctx_values(l_i));
    exception
      when e_incompatible_context or e_object_not_exist then
        l_i := c_supported_ctx_values.next(l_i);
    end;
  end loop;

  return false;
end try_to_resolve_ora_name;


procedure resolve_ora_name(
  in_ora_name in varchar2,
  out_owner out varchar2,
  out_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
)
is
  -- Regexp for the [SCHEMA.]NAME[@DBLINK] pattern.
  c_full_name_ptrn constant varchar2(64) := '^(([^.]+\.)??[^.@]+)(@([^@]+))?$';

  l_local_name varchar2(65);
  l_dblink varchar2(128);
begin
  -- Validate the name.
  if not nvl(regexp_like(in_ora_name, c_full_name_ptrn), false) then
    raise_application_error(
      gc_invalid_argument_num,
      'name ' || in_ora_name || ' does not match [SCHEMA.]NAME[@DBLINK] pattern'
    );
  end if;

  -- Split the name into two parts.
  l_local_name := regexp_replace(in_ora_name, c_full_name_ptrn, '\1');
  l_dblink := regexp_replace(in_ora_name, c_full_name_ptrn, '\4');

  if
    -- Try to resolve name with the Oracle native resolver.
    not try_to_resolve_ora_name(
      l_local_name, l_dblink, out_owner, out_name, out_dblink, out_type
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
procedure split_templ_name(
  in_templ_name in varchar2,
  out_container_name out varchar2,
  out_section_name out varchar2
)
is
begin
  if in_templ_name like '%\%%' escape '\' then
    out_container_name := regexp_replace(in_templ_name, '%[^%@]+');
    out_section_name :=
      regexp_replace(in_templ_name, '^([^%]+%?)([^%@]*)(@[^@]+)?$', '\2');
  else
    out_container_name := in_templ_name;
    out_section_name := null;
  end if;
end split_templ_name;


procedure resolve_templ_name(
  in_templ_name in varchar2,
  out_owner out varchar2,
  out_name out varchar2,
  out_sec_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
)
is
  l_container_name varchar2(200);
begin
  split_templ_name(in_templ_name, l_container_name, out_sec_name);
  resolve_ora_name(l_container_name, out_owner, out_name, out_dblink, out_type);
end resolve_templ_name;


function get_view_source(
  in_owner in varchar2,
  in_name in varchar2,
  in_dblink in varchar2
) return clob
is
  c_all_views_query constant varchar2(32767) :=
    'select v.text from all_views%dblink% v ' ||
    'where v.owner = :owner and v.view_name = :name';
begin
  return
    long2clob(
      replace(c_all_views_query, '%dblink%', a(in_dblink)),
      varchar2_nt(':owner', ':name'), varchar2_nt(in_owner, in_name)
    );
end get_view_source;


function get_program_unit_source(
  in_owner in varchar2,
  in_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return clob
is
  c_all_source_query constant varchar2(32767) :=
    'select s.text' || chr(10) ||
    'from all_source%dblink% s' || chr(10) ||
    'where' || chr(10) ||
    '  s.owner = :owner and' || chr(10) ||
    '  s.name = :name and' || chr(10) ||
    '  s.type in (:type, :type || '' BODY'')' || chr(10) ||
    'order by s.type, s.line';
  c_eol constant varchar2(1) :=
    case when in_type = 'JAVA SOURCE' then chr(10) end;
  l_src_lines dbms_sql.varchar2a;
  l_src clob;
begin
  execute immediate
    replace(c_all_source_query, '%dblink%', a(in_dblink))
  bulk collect into l_src_lines
  using in_owner, in_name, in_type, in_type;

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
  in_name in varchar2,
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
    when in_name is null then
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
      when c_type = 'VIEW' then get_view_source(in_owner, in_name, in_dblink)
      else get_program_unit_source(in_owner, in_name, in_dblink, c_type)
    end;

exception
  when no_data_found then
    raise_application_error(
      gc_source_not_found_num,
      utl_lms.format_message(
        gc_source_not_found_msg,
        in_owner || '.' || in_name || a(in_dblink), c_type
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
  in_name in varchar2,
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
      get_obj_source(in_owner, in_name, in_dblink, in_type),
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
        full_name(in_owner, in_name, in_dblink, in_type)
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
  l_name varchar2(30);
  l_dblink varchar2(128);
  l_type varchar2(30);
begin
  resolve_ora_name(in_container_name, l_owner, l_name, l_dblink, l_type);

  return
    extract_section_from_obj_src(
      l_owner, l_name, l_dblink, l_type,
      in_start_ptrn, in_end_ptrn, in_keep_boundaries,
      in_lazy_search, in_occurrence
    );
end extract_section_from_obj_src;


function extract_noncompiled_section(
  in_owner in varchar2,
  in_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return clob
is
begin
  return
    extract_section_from_obj_src(
      in_owner, in_name, in_dblink, in_type,
      gc_noncmp_section_start_ptrn, gc_noncmp_section_end_ptrn
    );
exception
  when e_section_not_found then
    raise_application_error(
      gc_section_not_found_num,
      utl_lms.format_message(
        gc_ncmp_section_not_found_msg,
        full_name(in_owner, in_name, in_dblink, in_type)
      )
    );
end extract_noncompiled_section;


function extract_noncompiled_section(in_container_name in varchar2) return clob
is
  l_owner varchar2(30);
  l_name varchar2(30);
  l_dblink varchar2(128);
  l_type varchar2(30);
begin
  resolve_ora_name(in_container_name, l_owner, l_name, l_dblink, l_type);

  return extract_noncompiled_section(l_owner, l_name, l_dblink, l_type);
end extract_noncompiled_section;


function escape_section_name(
  in_section_name in varchar2
) return varchar2
is
begin
  if not nvl(regexp_like(in_section_name, '^[[:alnum:]_#$]+$'), false) then
    raise_application_error(
      gc_invalid_argument_num,
      'section name "' || in_section_name ||
        '" contains characters that are not allowed'
    );
  end if;
  return replace(in_section_name, '$', '\$');
end escape_section_name;


function extract_named_section(
  in_owner in varchar2,
  in_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2,
  in_section_name in varchar2,
  in_occurrence in positiven := 1
) return clob
is
  c_section_name constant varchar2(100) := escape_section_name(in_section_name);
begin
  return
    extract_section_from_obj_src(
       in_owner, in_name, in_dblink, in_type,
      replace(gc_named_section_start_ptrn, '%name%', c_section_name),
      replace(gc_named_section_end_ptrn, '%name%', c_section_name),
      false, true, in_occurrence
    );
exception
  when e_section_not_found then
    raise_application_error(
      gc_section_not_found_num,
      utl_lms.format_message(
        gc_named_section_not_found_msg, in_occurrence,
        in_section_name, full_name(in_owner, in_name, in_dblink, in_type)
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
  l_name varchar2(30);
  l_dblink varchar2(128);
  l_type varchar2(30);
begin
  resolve_ora_name(in_container_name, l_owner, l_name, l_dblink, l_type);

  return
    extract_named_section(
      l_owner, l_name, l_dblink, l_type, in_section_name, in_occurrence
    );
end extract_named_section;


function count_matched_parentheses(in_pattern in varchar2) return pls_integer
is
  c_parentheses constant varchar2(4000) := regexp_replace(
    replace(replace(replace(in_pattern, '\\'), '\('), '\)'), '[^()]'
  );
  l_cnt pls_integer := 0;
  l_balance pls_integer := 0;
begin

  for l_i in 1..nvl(length(c_parentheses), 0) loop

    if substr(c_parentheses, l_i, 1) = '(' then
      l_cnt := l_cnt + 1;
      l_balance := l_balance + 1;
    else
      l_balance := l_balance - 1;
    end if;

    if l_balance < 0 then
      return -1;
    end if;

  end loop;

  return
    case
      when l_balance = 0 then l_cnt
      else -1
    end;
end count_matched_parentheses;


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
  l_start_ptrn_par_count pls_integer;
begin
  -- Check the argument values.
  if not nvl(in_lazy_search, false) and in_occurrence > 1 then
    raise_application_error(
      gc_invalid_argument_num,
      'occurrence cannot be specified for greedy search'
    );
  end if;

  if in_keep_boundaries then
    l_start_ptrn_par_count := count_matched_parentheses(in_start_ptrn);
    if l_start_ptrn_par_count = -1 then
      raise_application_error(
        gc_invalid_argument_num,
        'section start pattern "' || in_start_ptrn ||
          '" contains unmatched parentheses'
      );
    elsif l_start_ptrn_par_count > 7 then
      raise_application_error(
        gc_invalid_argument_num,
        'section start pattern "' || in_start_ptrn ||
          '" contains more then 7 pairs of parantheses'
      );
    end if;
  end if;

  -- Check that the section exists.
  if nvl(dbms_lob.getlength(regexp_substr(in_container,
      in_start_ptrn || '.*?' || in_end_ptrn, 1, in_occurrence, 'in')), 0) = 0
  then
    raise_application_error(
      gc_section_not_found_num,
      utl_lms.format_message(
        gc_section_not_found_msg, in_occurrence,
        in_start_ptrn, in_end_ptrn, 'in_container'
      )
    );
  end if;

  return
    regexp_replace(
      in_container,
      '(' || in_start_ptrn || ').*' ||
        case when in_lazy_search then '?' end ||
        '(' || in_end_ptrn || ')',
      case when in_keep_boundaries then '\1' end ||
        replace(in_replacement, '\', '\\') ||
        case when in_keep_boundaries then
          '\' || to_char(2 + l_start_ptrn_par_count)
        end,
      1, in_occurrence, 'in'
    );
end replace_section_in_clob;


function replace_named_section_in_clob(
  in_container clob,
  in_section_name varchar2,
  in_replacement clob,
  in_keep_boundaries in boolean := false,
  in_occurrence in positiven := 1
) return clob
is
  c_section_name constant varchar2(100) := escape_section_name(in_section_name);
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
