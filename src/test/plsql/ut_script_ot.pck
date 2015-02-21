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

create or replace package ut_script_ot as
/**
 * Unit tests for SCRIPT_OT type.
 */


procedure ut_constructor#clob_nt;
procedure ut_constructor#clob;

procedure ut_to_clob;

procedure ut_append#clob;
procedure ut_append#script;

procedure ut_show#statement;
procedure ut_show#script;

procedure ut_exec#statement;
procedure ut_exec#script;


end ut_script_ot;
/
create or replace package body ut_script_ot as


procedure ut_constructor#clob_nt
is
  l_clobs ftldb_clob_nt := ftldb_clob_nt(
    'statement1',
    'statement2',
    'statement3'
  );
  l_scr ftldb_script_ot;
begin
  l_scr := ftldb_script_ot(l_clobs);
  
  if not nvl(
    l_scr.statements.count() = 3 and
    l_scr.statements(1) = 'statement1' and
    l_scr.statements(2) = 'statement2' and
    l_scr.statements(3) = 'statement3',
    false
  ) then
    for l_i in 1..l_scr.statements.count() loop
      dbms_output.put_line(l_scr.statements(l_i));
    end loop;
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_constructor#clob_nt;


procedure ut_constructor#clob
is
  l_clob clob := 
    'statement1' || chr(10) ||
    '</>' || chr(10) ||
    'statement2' || chr(10) ||
    '</>' || chr(10) ||
    'statement3' || chr(10) ||
    '</>';
  l_scr ftldb_script_ot;
begin
  l_scr := ftldb_script_ot(l_clob, '</>');
  
  if not nvl(
    l_scr.statements.count() = 3 and
    l_scr.statements(1) = 'statement1' and
    l_scr.statements(2) = 'statement2' and
    l_scr.statements(3) = 'statement3',
    false
  ) then
    for l_i in 1..l_scr.statements.count() loop
      dbms_output.put_line(l_scr.statements(l_i));
    end loop;
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_constructor#clob;


procedure ut_to_clob
is
  l_scr ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'statement1',
    'statement2',
    'statement3'
  ));
  l_etalon clob := 
    'statement1' || chr(10) ||
    '/' || chr(10) ||
    'statement2' || chr(10) ||
    '/' || chr(10) ||
    'statement3' || chr(10) ||
    '/';  
  l_res clob;
begin
  l_res := l_scr.to_clob('/');
  
  if not nvl(
    dbms_lob.compare(l_res, l_etalon) = 0,
    false
  ) then
    ftldb_clob_util.show(l_res);
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_to_clob;


procedure ut_append#clob
is
  l_scr ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'statement1',
    'statement2'
  ));
  l_etalon ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'statement1',
    'statement2',
    'statement3'
  ));
begin
  l_scr.append('statement3');
  
  if not nvl(
    l_scr.statements = l_etalon.statements,
    false
  ) then
    for l_i in 1..l_scr.statements.count() loop
      dbms_output.put_line(l_scr.statements(l_i));
     end loop;
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_append#clob;


procedure ut_append#script
is
  l_scr ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'statement1',
    'statement2'
  ));
  l_etalon ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'statement1',
    'statement2',
    'statement3',
    'statement4'
  ));
begin
  l_scr.append(ftldb_script_ot(ftldb_clob_nt('statement3', 'statement4')));
  
  if not nvl(
    l_scr.statements = l_etalon.statements,
    false
  ) then
    for l_i in 1..l_scr.statements.count() loop
      dbms_output.put_line(l_scr.statements(l_i));
     end loop;
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_append#script;


procedure ut_show#statement
is
  l_scr ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'statement1',
    'statement2',
    'statement3'
  ));
  l_lines dbmsoutput_linesarray;
  l_cnt number;
begin
  l_scr.show(2);
  
  dbms_output.get_lines(l_lines, l_cnt);
  
  if not nvl(
    l_cnt = 2 and
    l_lines(1) = l_scr.statements(2) and
    l_lines(2) = '/',
    false
  ) then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
     end loop;
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_show#statement;


procedure ut_show#script
is
  l_scr ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'statement1',
    'statement2'
  ));
  l_lines dbmsoutput_linesarray;
  l_cnt number;
begin
  l_scr.show();
  
  dbms_output.get_lines(l_lines, l_cnt);
  
  if not nvl(
    l_cnt = 4 and
    l_lines(1) = l_scr.statements(1) and
    l_lines(2) = '/' and
    l_lines(3) = l_scr.statements(2) and
    l_lines(4) = '/',
    false
  ) then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
     end loop;
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_show#script;

procedure ut_exec#statement
is
  l_scr ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'statement1',
    'begin dbms_output.put_line(''123''); end;'
  ));
  l_lines dbmsoutput_linesarray;
  l_cnt number;
begin
  l_scr.exec(2, true);
  
  dbms_output.get_lines(l_lines, l_cnt);
  
  if not nvl(
    l_cnt = 3 and
    l_lines(1) = l_scr.statements(2) and
    l_lines(2) = '/' and
    l_lines(3) = '123',
    false
  ) then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
     end loop;
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_exec#statement;


procedure ut_exec#script
is
  l_scr ftldb_script_ot := ftldb_script_ot(ftldb_clob_nt(
    'begin raise value_error; end;',
    'begin dbms_output.put_line(''123''); end;'
  ));
  l_lines dbmsoutput_linesarray;
  l_cnt number;
begin
  l_scr.exec(true, true);
  
  dbms_output.get_lines(l_lines, l_cnt);
  
  if not nvl(
    l_cnt = 6 and
    l_lines(1) = l_scr.statements(1) and
    l_lines(2) = '/' and
    l_lines(3) like 'error suppressed in statement #1 (' ||
                    l_scr.statements(1) || ')%' and
    l_lines(4) = l_scr.statements(2) and
    l_lines(5) = '/' and
    l_lines(6) = '123',
    false
  ) then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
     end loop;
    raise_application_error(-20000, 'Result is not as expected');  
  end if;
end ut_exec#script;


end ut_script_ot;
/
