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

create or replace package body clob_util as


-- Blank characters: space and tab.
gc_blank constant varchar2(2 byte) := ' ' || chr(9);

-- LF character (*nix EOL).
gc_lf constant varchar2(1 byte) := chr(10);

-- CRLF characters (Win EOL).
gc_crlf constant varchar2(2 byte) := chr(13) || chr(10);

-- EOL pattern: LF or CRLF.
gc_eol constant varchar2(6 byte) := '(' || gc_lf || '|' || gc_crlf || ')';


function create_temporary(in_content in varchar2 := '') return clob
is
  l_clob clob;
begin
  dbms_lob.createtemporary(l_clob, true);
  if in_content is not null then
    put(l_clob, in_content);
  end if;
  return l_clob;
end create_temporary;


procedure ensure_trailing_lf(io_clob in out nocopy clob)
is
begin
  if dbms_lob.substr(io_clob, 1, dbms_lob.getlength(io_clob)) != gc_lf then
    dbms_lob.writeappend(io_clob, 1, gc_lf);
  end if;
end;


procedure put(
  io_clob in out nocopy clob,
  in_string in varchar2,
  in_indent in natural := null
)
is
  c_indented_string constant varchar2(32767 byte) :=
    rpad(' ', nvl(in_indent, 0), ' ') || in_string;
begin
  if in_indent is not null then
    ensure_trailing_lf(io_clob);
  end if;
  if c_indented_string is not null then
    dbms_lob.writeappend(io_clob, length(c_indented_string), c_indented_string);
  end if;
end put;


procedure put_line(
  io_clob in out nocopy clob,
  in_string in varchar2 := '',
  in_indent in natural := null
)
is
begin
  put(io_clob, in_string || gc_lf, in_indent);
end put_line;


procedure append(
  io_clob in out nocopy clob,
  in_text in clob,
  in_indent in natural := null
)
is
  l_space varchar2(32767 byte);
begin
  if in_indent is not null then
    ensure_trailing_lf(io_clob);
  end if;
  if in_indent > 0 then
    l_space := rpad(' ', in_indent, ' ');
    dbms_lob.append(io_clob, regexp_replace(in_text, '^', l_space, 1, 0, 'm'));
  else
    dbms_lob.append(io_clob, in_text);
  end if;
end append;


function trim_blank_lines(in_clob in clob) return clob
is
  c_blank_line_ptrn constant varchar2(64 byte) :=
    '[' || gc_blank ||']*' || gc_eol;
  c_filled_line_ptrn constant varchar2(64 byte) :=
    '[^[:space:]]+[' || gc_blank ||']*' || gc_eol;
  c_leading_lines_ptrn constant varchar2(64 byte) :=
    '^(' || c_blank_line_ptrn || ')*';
  c_trailing_lines_ptrn constant varchar2(64 byte) :=
    '(' || c_filled_line_ptrn || ')?(' || c_blank_line_ptrn || ')*$';
begin
  return
    regexp_replace(
      regexp_replace(in_clob, c_leading_lines_ptrn), c_trailing_lines_ptrn, '\1'
    );
end trim_blank_lines;


function join(
  in_clobs in clob_nt,
  in_delim in varchar2 := '',
  in_final_delim in boolean := false,
  in_refine_lines in boolean := false
) return clob
is
  l_i pls_integer := in_clobs.first();
  l_i_next pls_integer;
  l_tmp clob;
  l_res clob := create_temporary();
begin
  while l_i is not null loop
    l_i_next := in_clobs.next(l_i);
    if in_refine_lines then
      l_tmp := trim_blank_lines(in_clobs(l_i));
      if dbms_lob.getlength(l_tmp) > 0 then
        append(l_res, l_tmp, 0);
        if in_final_delim or l_i_next is not null and in_delim is not null then
          append(l_res, in_delim, 0);
        end if;
      end if;
    else
      append(l_res, in_clobs(l_i));
      if in_final_delim or l_i_next is not null then
        put(l_res, in_delim);
      end if;
    end if;
    l_i := l_i_next;
  end loop;
  return l_res;
end join;


function split_into_lines(in_clob in clob) return dbms_sql.varchar2a
is
  c_length constant integer := dbms_lob.getlength(in_clob);
  l_start_pos integer := 1;
  l_eol_pos integer;
  l_lines dbms_sql.varchar2a;
  l_no pls_integer := 0;
begin
  if in_clob is null or c_length = 0 then
    return l_lines;
  end if;

  loop
    l_eol_pos := regexp_instr(in_clob, gc_eol, l_start_pos, 1, 0, 'n');

    if l_eol_pos = 0 then
      l_eol_pos := c_length + 1;
    end if;

    l_no := l_no + 1;
    l_lines(l_no) :=
      dbms_lob.substr(in_clob, l_eol_pos - l_start_pos, l_start_pos);

    exit when l_eol_pos > c_length;

    l_start_pos := regexp_instr(in_clob, gc_eol, l_start_pos, 1, 1, 'n');
    exit when l_start_pos >= c_length;
  end loop;

  return l_lines;
end split_into_lines;


function split_into_pieces(
  in_clob in clob,
  in_delim_ptrn in varchar2,
  in_regexp_mdfr in varchar2,
  in_trim_lines in boolean := false
) return clob_nt
is
  c_length constant integer := dbms_lob.getlength(in_clob);
  l_start_pos integer := 1;
  l_end_pos integer;
  l_tmp clob;
  l_res clob_nt := clob_nt();
begin
  if in_clob is null or c_length = 0 then
    return l_res;
  end if;

  loop
    l_end_pos :=
      regexp_instr(in_clob, in_delim_ptrn, l_start_pos, 1, 0, in_regexp_mdfr);

    if nvl(l_end_pos, 0) = 0 then
      l_end_pos := c_length + 1;
    end if;

    if l_start_pos < l_end_pos then
      l_tmp := create_temporary();
      dbms_lob.copy(l_tmp, in_clob, l_end_pos - l_start_pos, 1, l_start_pos);
      if in_trim_lines then
        l_tmp := trim_blank_lines(l_tmp);
      end if;
      if dbms_lob.getlength(l_tmp) > 0 then
        l_res.extend();
        l_res(l_res.last()) := l_tmp;
      end if;
    end if;

    exit when l_end_pos > c_length;

    l_start_pos :=
      regexp_instr(in_clob, in_delim_ptrn, l_start_pos, 1, 1, in_regexp_mdfr);
    exit when l_start_pos >= c_length;
  end loop;

  return l_res;
end split_into_pieces;


/**
 * Prints the given lines to DBMS_OUTPUT with the ending character.
 *
 * @param  in_lines  the lines to be printed
 * @param  in_eof    the ending character (optional)
 */
procedure show(in_lines in dbms_sql.varchar2a, in_eof in varchar2 := '')
is
begin
  for i in 1..in_lines.count() loop
    dbms_output.put_line(in_lines(i));
  end loop;

  if in_eof is not null then
    dbms_output.put_line(in_eof);
  end if;
end show;


procedure show(in_clob in clob, in_eof in varchar2 := '')
is
begin
  show(split_into_lines(in_clob), in_eof);
end show;


procedure exec(in_clob in clob, in_echo in boolean := false)
is
  l_lines dbms_sql.varchar2a;
  $if dbms_db_version.version < 11 $then
    l_clob_is_large boolean := false;
    l_str varchar2(32767 byte);
    l_cur integer;
    l_res integer;
  $end
begin
  -- By default the CLOB is executed via Native Dynamic SQL, but if its size
  -- exceeds 32767 bytes and the Oracle version is less then 11g, the CLOB is
  -- executed via DBMS_SQL.
  $if dbms_db_version.version < 11 $then
    -- Try to put the CLOB into a varchar2 variable. If it doesn't fit,
    -- to_char() raises the VALUE_ERROR exception.
    begin
      l_str := to_char(in_clob);
    exception
      when value_error then
        l_clob_is_large := true;
    end;
  $end

  -- Split the CLOB into lines only in case of printing or executing via
  -- DBMS_SQL
  if in_echo $if dbms_db_version.version < 11 $then or l_clob_is_large $end then
    l_lines := split_into_lines(in_clob);
  end if;

  if in_echo then
    show(l_lines, '/');
  end if;

  $if dbms_db_version.version < 11 $then
    if l_clob_is_large then
      begin
        l_cur := dbms_sql.open_cursor();
        dbms_sql.parse(
          l_cur, l_lines, 1, l_lines.count(), true, dbms_sql.native
        );
        l_res := dbms_sql.execute(l_cur);
        dbms_sql.close_cursor(l_cur);
      exception
        when others then
          if dbms_sql.is_open(l_cur) then
            dbms_sql.close_cursor(l_cur);
          end if;
          raise;
      end;
    else
      execute immediate l_str;
    end if;
  $else
    execute immediate in_clob;
  $end
end exec;


end clob_util;
/
