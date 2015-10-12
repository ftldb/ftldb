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

create or replace package ut_clob_util as
/**
 * Unit tests for CLOB_UTIL package.
 */


procedure ut_create_temporary;


procedure ut_put;


procedure ut_put_line;


procedure ut_append;


procedure ut_join;


procedure ut_split_into_lines;


procedure ut_split_into_pieces;


procedure ut_show;


procedure ut_exec;


end ut_clob_util;
/
create or replace package body ut_clob_util as


procedure ut_create_temporary
is
  l_clob clob;
  l_init_val varchar2(100) := 'ABC';
BEGIN
  l_clob := ftldb_clob_util.create_temporary();
  if l_clob is null then
    raise_application_error(-20000, 'Created clob is null');
  end if;
  if dbms_lob.istemporary(l_clob) != 1 then
    raise_application_error(-20000, 'Created clob is not temporary');
  end if;
  if dbms_lob.getlength(l_clob) != 0 then
    raise_application_error(-20000, 'Created clob is not empty');
  end if;

  l_clob := ftldb_clob_util.create_temporary(l_init_val);
  if l_clob != l_init_val then
    dbms_output.put_line(l_clob);
    raise_application_error(-20000, 'Created clob is not as expected');
  end if;
end ut_create_temporary;


procedure ut_put
is
  l_clob clob := ftldb_clob_util.create_temporary('ABC');
begin
  ftldb_clob_util.put(l_clob, 'DEF', 2);
  if l_clob != 'ABC' || chr(10) || '  DEF' then
    dbms_output.put_line(l_clob);
    raise_application_error(-20000, 'Created clob is not as expected');
  end if;
end ut_put;


procedure ut_put_line
is
  l_clob clob := ftldb_clob_util.create_temporary('ABC');
begin
  ftldb_clob_util.put_line(l_clob, 'DEF', 2);
  if l_clob != 'ABC' || chr(10) || '  DEF' || chr(10) then
    dbms_output.put_line(l_clob);
    raise_application_error(-20000, 'Created clob is not as expected');
  end if;
end ut_put_line;


procedure ut_append
is
  l_clob1 clob := ftldb_clob_util.create_temporary('ABC' || chr(10));
  l_clob2 clob := ftldb_clob_util.create_temporary('DEF' || chr(10) || 'GHI');
begin
  ftldb_clob_util.append(l_clob1, l_clob2, 2);
  if l_clob1 != 'ABC' || chr(10) || '  DEF' || chr(10) || '  GHI' then
    dbms_output.put_line(l_clob1);
    raise_application_error(-20000, 'Created clob is not as expected');
  end if;
end ut_append;


procedure ut_join
is
  l_clobs ftldb_clob_nt;
  l_join clob;
begin
  l_clobs := ftldb_clob_nt('ABC', 'DEF', 'GHI');
  l_join := ftldb_clob_util.join(l_clobs, ', ');
  if l_join != 'ABC, DEF, GHI' then
    dbms_output.put_line(l_join);
    raise_application_error(-20000, 'Joined clob is not as expected');
  end if;

  l_join := ftldb_clob_util.join(l_clobs, ';', true);
  if l_join != 'ABC;DEF;GHI;' then
    dbms_output.put_line(l_join);
    raise_application_error(-20000, 'Joined clob is not as expected');
  end if;

  l_clobs := ftldb_clob_nt('ABC', ' DEF' || chr(10), 'GHI ');
  l_join := ftldb_clob_util.join(l_clobs, '/', true, true);
  if l_join != replace('ABC$/$ DEF$/$GHI $/', '$', chr(10)) then
    dbms_output.put_line(l_join);
    raise_application_error(-20000, 'Joined clob is not as expected');
  end if;
end ut_join;


procedure ut_split_into_lines
is
  l_clob clob :=
    'ABC' || chr(10) ||
    'DEF' || chr(10) ||
    'GHI' || chr(10);
  l_lines dbms_sql.varchar2a;
begin
  l_lines := ftldb_clob_util.split_into_lines(l_clob);
  if not (
    l_lines.count() = 3 and
    l_lines(1) = 'ABC' and
    l_lines(2) = 'DEF' and
    l_lines(3) = 'GHI'
  ) then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
    end loop;
    raise_application_error(-20000, 'Resulting array is not as expected');
  end if;
end ut_split_into_lines;


procedure ut_split_into_pieces
is
  l_clob clob :=
    '  ABC' || chr(10) ||
    'DEF' || chr(10) ||
    '' || chr(10) ||
    '//' || chr(10) ||
    'GHI' || chr(10) ||
    'JKL' || chr(10) ||
    '//';
  l_clobs ftldb_clob_nt;
begin
  l_clobs := ftldb_clob_util.split_into_pieces(l_clob, '\s*//\s*');
  if not (
    l_clobs.count() = 2 and
    l_clobs(1) = '  ABC' || chr(10) || 'DEF' and
    l_clobs(2) = 'GHI' || chr(10) || 'JKL'
  ) then
    for l_i in 1..l_clobs.count() loop
      dbms_output.put_line(l_clobs(l_i));
    end loop;
    raise_application_error(-20000, 'Resulting array is not as expected');
  end if;
end ut_split_into_pieces;


procedure ut_show
is
  l_clob clob :=
    'ABC' || chr(10) ||
    'DEF' || chr(10) ||
    'GHI' || chr(10) ||
    'JKL';
  l_lines dbmsoutput_linesarray;
  l_cnt number := 5;
begin
  ftldb_clob_util.show(l_clob, '/');
  dbms_output.get_lines(l_lines, l_cnt);
  if not (
    l_lines.count() = 5 and
    l_lines(1) = 'ABC' and
    l_lines(2) = 'DEF' and
    l_lines(3) = 'GHI' and
    l_lines(4) = 'JKL' and
    l_lines(5) = '/'
  ) then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
    end loop;
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_show;


procedure ut_exec
is
  l_clob clob := ftldb_clob_util.create_temporary();
  l_proc_name varchar2(30) := 'ut_clob_util$ut_exec$testproc';
begin
  ftldb_clob_util.put_line(
    l_clob, 'create or replace procedure ' || l_proc_name || ' as'
  );
  ftldb_clob_util.put_line(l_clob, 'begin null;');
  for l_i in 1..2000 loop
    ftldb_clob_util.put_line(l_clob, '--01234567890ABCDEF01234567890ABCDEF');
  end loop;
  ftldb_clob_util.put_line(l_clob, 'end;');

  ftldb_clob_util.exec(l_clob);
  ftldb_clob_util.exec('drop procedure ' || l_proc_name);
end ut_exec;


end ut_clob_util;
/
