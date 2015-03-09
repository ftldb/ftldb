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

create or replace package ut_source_util as
/**
 * Unit tests for SOURCE_UTIL package.
 */


procedure ut_long2clob;

procedure ut_resolve_name#own_object;
procedure ut_resolve_name#others_object;
procedure ut_resolve_name#dblink_object;
procedure ut_resolve_name#dblink_oth_obj;

procedure ut_get_obj_source#view;
procedure ut_get_obj_source#func;

procedure ut_extr_sect_from_clob#default;
procedure ut_extr_sect_from_clob#w_bound;
procedure ut_extr_sect_from_clob#lazy;
procedure ut_extr_sect_from_clob#greedy;

procedure ut_extr_sect_from_obj#w_bound;
procedure ut_extr_noncmp_sect;
procedure ut_extr_named_sect;

procedure ut_repl_sect_in_clob#default;
procedure ut_repl_sect_in_clob#w_bound;
procedure ut_repl_sect_in_clob#lazy;
procedure ut_repl_sect_in_clob#greedy;

procedure ut_repl_nm_sect_in_clob#lazy;
procedure ut_repl_nm_sect_in_clob#greedy;


end ut_source_util;
/
create or replace package body ut_source_util as


procedure ut_long2clob
is
  c_view_name constant varchar2(30) := 'ut_source_util$long2clob$vw';
  l_view clob;
  l_lines dbms_sql.varchar2a;
  l_valid_flg boolean := true;
begin
  l_view :=
    ftldb_source_util.long2clob(
      'select text from user_views where view_name = upper(:1)',
      ftldb_varchar2_nt(':1'), ftldb_varchar2_nt(c_view_name)
    );

  l_lines := ftldb_clob_util.split_into_lines(l_view);

  for l_i in 1..l_lines.count() loop
    if
      l_lines(l_i) !=
        case
          when l_i = 1 then 'select 1 x'
          when l_i = l_lines.count() then 'from dual'
          else '--01234567890ABCDEF01234567890ABCDEF'
        end
    then
      l_valid_flg := false;
    end if;
  end loop;

  if not l_valid_flg then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
    end loop;
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_long2clob;


procedure ut_resolve_name#own_object
is
  c_name constant varchar2(190) := lower($$plsql_unit);
  l_obj_owner varchar2(30);
  l_obj_name varchar2(30);
  l_obj_dblink varchar2(128);
  l_obj_type varchar2(30);
begin
  ftldb_source_util.resolve_name(
    c_name,
    l_obj_owner, l_obj_name, l_obj_dblink, l_obj_type
  );
  if not nvl(
    l_obj_owner = sys_context('userenv', 'current_schema') and
    l_obj_name = $$plsql_unit and
    l_obj_dblink is null and
    l_obj_type = 'PACKAGE',
    false
  ) then
    dbms_output.put_line('name=' || c_name);
    dbms_output.put_line('obj_owner=' || l_obj_owner);
    dbms_output.put_line('obj_name=' || l_obj_name);
    dbms_output.put_line('obj_dblink=' || l_obj_dblink);
    dbms_output.put_line('obj_type=' || l_obj_type);
    raise_application_error(-20000, 'Resolved attributes are not as expected');
  end if;
end ut_resolve_name#own_object;


procedure ut_resolve_name#others_object
is
  c_name constant varchar2(190) :=
    sys_context('userenv', 'current_schema') || '_ext1.testfunc';
  l_obj_owner varchar2(30);
  l_obj_name varchar2(30);
  l_obj_dblink varchar2(128);
  l_obj_type varchar2(30);
begin
  ftldb_source_util.resolve_name(
    c_name,
    l_obj_owner, l_obj_name, l_obj_dblink, l_obj_type
  );
  if not nvl(
    l_obj_owner = sys_context('userenv', 'current_schema') || '_EXT1' and
    l_obj_name = upper('testfunc') and
    l_obj_dblink is null and
    l_obj_type = 'FUNCTION',
    false
  ) then
    dbms_output.put_line('name=' || c_name);
    dbms_output.put_line('obj_owner=' || l_obj_owner);
    dbms_output.put_line('obj_name=' || l_obj_name);
    dbms_output.put_line('obj_dblink=' || l_obj_dblink);
    dbms_output.put_line('obj_type=' || l_obj_type);
    raise_application_error(-20000, 'Resolved attributes are not as expected');
  end if;
end ut_resolve_name#others_object;


procedure ut_resolve_name#dblink_object
is
  c_name constant varchar2(190) :=
    'testfunc' || '@' || sys_context('userenv', 'current_schema') || '$ext1';
  l_obj_owner varchar2(30);
  l_obj_name varchar2(30);
  l_obj_dblink varchar2(128);
  l_obj_type varchar2(30);
begin
  ftldb_source_util.resolve_name(
    c_name,
    l_obj_owner, l_obj_name, l_obj_dblink, l_obj_type
  );
  rollback; -- release the transaction lock from the remote undo segment
  if not nvl(
    l_obj_owner = sys_context('userenv', 'current_schema') || '_EXT1' and
    l_obj_name = upper('testfunc') and
    upper(l_obj_dblink) like
       upper(sys_context('userenv', 'current_schema') || '$ext1%') and
    l_obj_type = 'FUNCTION',
    false
  ) then
    dbms_output.put_line('name=' || c_name);
    dbms_output.put_line('obj_owner=' || l_obj_owner);
    dbms_output.put_line('obj_name=' || l_obj_name);
    dbms_output.put_line('obj_dblink=' || l_obj_dblink);
    dbms_output.put_line('obj_type=' || l_obj_type);
    raise_application_error(-20000, 'Resolved attributes are not as expected');
  end if;
end ut_resolve_name#dblink_object;


procedure ut_resolve_name#dblink_oth_obj
is
  c_name constant varchar2(190) :=
    sys_context('userenv', 'current_schema') || '_ext2.testview' || '@' ||
    sys_context('userenv', 'current_schema') || '$ext1';
  l_obj_owner varchar2(30);
  l_obj_name varchar2(30);
  l_obj_dblink varchar2(128);
  l_obj_type varchar2(30);
begin
  ftldb_source_util.resolve_name(
    c_name,
    l_obj_owner, l_obj_name, l_obj_dblink, l_obj_type
  );
  rollback;
  if not nvl(
    l_obj_owner = sys_context('userenv', 'current_schema') || '_EXT2' and
    l_obj_name = upper('testview') and
    upper(l_obj_dblink) like
      upper(sys_context('userenv', 'current_schema') || '$ext1%') and
    l_obj_type = 'VIEW',
    false
  ) then
    dbms_output.put_line('name=' || c_name);
    dbms_output.put_line('obj_owner=' || l_obj_owner);
    dbms_output.put_line('obj_name=' || l_obj_name);
    dbms_output.put_line('obj_dblink=' || l_obj_dblink);
    dbms_output.put_line('obj_type=' || l_obj_type);
    raise_application_error(-20000, 'Resolved attributes are not as expected');
  end if;
end ut_resolve_name#dblink_oth_obj;


procedure ut_get_obj_source#view
is
  l_src clob;
  l_lines dbms_sql.varchar2a;
  l_valid_flg boolean := true;
begin
  l_src :=
    ftldb_source_util.get_obj_source(
      sys_context('userenv', 'current_schema') || '_EXT2',
      upper('testview'),
      sys_context('userenv', 'current_schema') || '$EXT1',
      'VIEW'
    );
  rollback;

  l_lines := ftldb_clob_util.split_into_lines(l_src);

  for l_i in 1..l_lines.count() loop
    if
      l_lines(l_i) !=
        case
          when l_i = 1 then 'select 1 x'
          when l_i = l_lines.count() then 'from dual'
        end
    then
      l_valid_flg := false;
    end if;
  end loop;

  if not l_valid_flg then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
    end loop;
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_get_obj_source#view;


procedure ut_get_obj_source#func
is
  l_src clob;
  l_lines dbms_sql.varchar2a;
  l_valid_flg boolean := true;
begin
  l_src :=
    ftldb_source_util.get_obj_source(
      sys_context('userenv', 'current_schema') || '_EXT1',
      upper('testfunc'),
      sys_context('userenv', 'current_schema') || '$EXT1',
      'FUNCTION'
    );
  rollback;

  l_lines := ftldb_clob_util.split_into_lines(l_src);

  for l_i in 1..l_lines.count() loop
    if
      l_lines(l_i) !=
        case
          when l_i = 1 then 'function testfunc return number as'
          when l_i = l_lines.count() then 'begin return null; end;'
        end
    then
      l_valid_flg := false;
    end if;
  end loop;

  if not l_valid_flg then
    for l_i in 1..l_lines.count() loop
      dbms_output.put_line(l_lines(l_i));
    end loop;
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_get_obj_source#func;


procedure ut_extr_sect_from_clob#default
is
  l_src clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  GHI' || chr(10) ||
    '--';
  l_etalon clob :=
    'DEF';
begin
  l_src :=
    ftldb_source_util.extract_section_from_clob(
      l_src,
      '<begin>', '<end>'
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_extr_sect_from_clob#default;


procedure ut_extr_sect_from_clob#w_bound
is
  l_src clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  GHI' || chr(10) ||
    '--';
  l_etalon clob :=
    '<begin>DEF<end>';
begin
  l_src :=
    ftldb_source_util.extract_section_from_clob(
      l_src,
      '<begin>', '<end>', true
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_extr_sect_from_clob#w_bound;


procedure ut_extr_sect_from_clob#lazy
is
  l_src clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  <begin>GHI<end>' || chr(10) ||
    '  <begin>JKL<end>' || chr(10) ||
    '  MNO' || chr(10) ||
    '--';
  l_etalon clob :=
    '<begin>JKL<end>';
begin
  l_src :=
    ftldb_source_util.extract_section_from_clob(
      l_src,
      '<begin>', '<end>', true, true, 3
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_extr_sect_from_clob#lazy;


procedure ut_extr_sect_from_clob#greedy
is
  l_src clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  <begin>GHI<end>' || chr(10) ||
    '  <begin>JKL<end>' || chr(10) ||
    '  MNO' || chr(10) ||
    '--';
  l_etalon clob :=
      '<begin>DEF<end>' || chr(10) ||
    '  <begin>GHI<end>' || chr(10) ||
    '  <begin>JKL<end>';
begin
  l_src :=
    ftldb_source_util.extract_section_from_clob(
      l_src,
      '<begin>', '<end>', true, false
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_extr_sect_from_clob#greedy;


procedure ut_extr_sect_from_obj#w_bound
is
  l_src clob;
  l_etalon clob :=
    '<begin>xxx<end>';
begin
  l_src :=
    ftldb_source_util.extract_section_from_obj_src(
      'ut_source_util$extract_sect',
      '<begin>', '<end>', true
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_extr_sect_from_obj#w_bound;


procedure ut_extr_noncmp_sect
is
  l_src clob;
  l_etalon clob :=
    '   <begin>xxx<end>' || chr(10) ||
    '' || chr(10) ||
    '-- %Begin AAA' || chr(10) ||
    '     section A' || chr(10) ||
    '  --%End aaa' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%begin Bbb' || chr(10) ||
    '     section B' || chr(10) ||
    '  --%end bbb' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%Begin AAA' || chr(10) ||
    '     section A2' || chr(10) ||
    '  --%end AAA' || chr(10) ||
    '' || chr(10);
begin
  l_src :=
    ftldb_source_util.extract_noncompiled_section(
      'ut_source_util$extract_sect'
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_extr_noncmp_sect;


procedure ut_extr_named_sect
is
  l_src clob;
  l_etalon clob :=
    '     section A2' || chr(10);
begin
  l_src :=
    ftldb_source_util.extract_named_section(
      'ut_source_util$extract_sect', 'aaa', 2
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_extr_named_sect;


procedure ut_repl_sect_in_clob#default
is
  l_src clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  GHI' || chr(10) ||
    '--';
  l_etalon clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  xxx' || chr(10) ||
    '  GHI' || chr(10) ||
    '--';
begin
  l_src :=
    ftldb_source_util.replace_section_in_clob(
      l_src,
      '<begin>', '<end>', 'xxx'
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_repl_sect_in_clob#default;


procedure ut_repl_sect_in_clob#w_bound
is
  l_src clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  GHI' || chr(10) ||
    '--';
  l_etalon clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>xxx<end>' || chr(10) ||
    '  GHI' || chr(10) ||
    '--';
begin
  l_src :=
    ftldb_source_util.replace_section_in_clob(
      l_src,
      '<begin>', '<end>', 'xxx', true
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_repl_sect_in_clob#w_bound;


procedure ut_repl_sect_in_clob#lazy
is
  l_src clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  <begin>GHI<end>' || chr(10) ||
    '  <begin>JKL<end>' || chr(10) ||
    '  MNO' || chr(10) ||
    '--';
  l_etalon clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  <begin>GHI<end>' || chr(10) ||
    '  <begin>xxx<end>' || chr(10) ||
    '  MNO' || chr(10) ||
    '--';
begin
  l_src :=
    ftldb_source_util.replace_section_in_clob(
      l_src,
      '<begin>', '<end>', 'xxx', true, true, 3
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_repl_sect_in_clob#lazy;


procedure ut_repl_sect_in_clob#greedy
is
  l_src clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  <begin>DEF<end>' || chr(10) ||
    '  <begin>GHI<end>' || chr(10) ||
    '  <begin>JKL<end>' || chr(10) ||
    '  MNO' || chr(10) ||
    '--';
  l_etalon clob :=
    '--' || chr(10) ||
    '  ABC' || chr(10) ||
    '  xxx' || chr(10) ||
    '  MNO' || chr(10) ||
    '--';
begin
  l_src :=
    ftldb_source_util.replace_section_in_clob(
      l_src,
      '<begin>', '<end>', 'xxx', false, false
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_repl_sect_in_clob#greedy;


procedure ut_repl_nm_sect_in_clob#lazy
is
  l_src clob :=
    '-- %Begin AAA' || chr(10) ||
    '     section A' || chr(10) ||
    '  --%End aaa' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%begin Bbb' || chr(10) ||
    '     section B' || chr(10) ||
    '  --%end bbb' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%Begin AAA' || chr(10) ||
    '     section A2' || chr(10) ||
    '  --%end AAA' || chr(10) ||
    '' || chr(10);
  l_etalon clob :=
    '-- %Begin AAA' || chr(10) ||
    '     section A' || chr(10) ||
    '  --%End aaa' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%begin Bbb' || chr(10) ||
    '     section B' || chr(10) ||
    '  --%end bbb' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    'xxx' || chr(10) ||
    '' || chr(10);
begin
  l_src :=
    ftldb_source_util.replace_named_section_in_clob(
      l_src,
      'aaa', 'xxx' || chr(10), false, 2
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_repl_nm_sect_in_clob#lazy;


procedure ut_repl_nm_sect_in_clob#greedy
is
  l_src clob :=
    '-- %Begin AAA' || chr(10) ||
    '     section A' || chr(10) ||
    '  --%End aaa' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%begin Bbb' || chr(10) ||
    '     section B' || chr(10) ||
    '  --%end bbb' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%Begin AAA' || chr(10) ||
    '     section A2' || chr(10) ||
    '  --%end AAA' || chr(10) ||
    '' || chr(10);
  l_etalon clob :=
    '-- %Begin AAA' || chr(10) ||
    '     section A' || chr(10) ||
    '  --%End aaa' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%begin Bbb' || chr(10) ||
    '     section B' || chr(10) ||
    '  --%end bbb' || chr(10) ||
    '' || chr(10) ||
    '' || chr(10) ||
    '  --%Begin AAA' || chr(10) ||
    'xxx' || chr(10) ||
    '  --%end AAA' || chr(10) ||
    '' || chr(10);
begin
  l_src :=
    ftldb_source_util.replace_named_section_in_clob(
      l_src,
      'aaa', 'xxx' || chr(10), true, 2
    );

  if not nvl(dbms_lob.compare(l_src, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_src);
    raise_application_error(-20000, 'Output is not as expected');
  end if;
end ut_repl_nm_sect_in_clob#greedy;


end ut_source_util;
/
