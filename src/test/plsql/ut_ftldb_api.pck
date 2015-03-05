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

create or replace package ut_ftldb_api is
/**
 * Unit tests for FTLDB_API package.
 */

procedure ut_dflt_templ_loader#proc;
procedure ut_dflt_templ_loader#sect;

procedure ut_process#args;
procedure ut_process#include_args;
procedure ut_process#java_binds;
procedure ut_process#java_hlp_methods1;
procedure ut_process#java_hlp_methods2;
procedure ut_process#standard;
procedure ut_process#sql;


end ut_ftldb_api;
/
create or replace package body ut_ftldb_api is


procedure ut_dflt_templ_loader#proc
is
  l_tmpl clob;
  l_etalon clob :=
    '  <#if (2 > 1)>' || chr(10) ||
    '    true' || chr(10) ||
    '  </#if>' || chr(10);
begin
  $if null $then
  <#if (2 > 1)>
    true
  </#if>
  $end

  l_tmpl := ftldb_api.default_template_loader(
    'ut_ftldb_api'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_dflt_templ_loader#proc;


procedure ut_dflt_templ_loader#sect
is
  l_tmpl clob;
  l_etalon clob :=
    '  <#list 1..10 as i>' || chr(10) ||
    '  ${i}' || chr(10) ||
    '  </#list>' || chr(10);
begin
  /*
  --%begin ut_dflt_templ_loader#sect
  <#list 1..10 as i>
  ${i}
  </#list>
  --%end ut_dflt_templ_loader#sect
  */

  l_tmpl := ftldb_api.default_template_loader(
    'ut_ftldb_api%ut_dflt_templ_loader#sect'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_dflt_templ_loader#sect;


procedure ut_process#args
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%args', ftldb_varchar2_nt('x', 'y', 'z')
  );

  l_etalon := ftldb_api.default_template_loader(
    'ut_ftldb_api$process%args_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_process#args;


procedure ut_process#include_args
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_body_to_clob(
    '<#import "ftldb_standard_ftl" as std/>' || chr(10) ||
    '<@std.include "ut_ftldb_api$process%args", ["x", "y", "z"]/>'
  );

  l_etalon := ftldb_api.default_template_loader(
    'ut_ftldb_api$process%args_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_process#include_args;


procedure ut_process#java_binds
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%java_binds'
  );

  l_etalon := ftldb_api.default_template_loader(
    'ut_ftldb_api$process%java_binds_res' ||
    case when dbms_db_version.version < 11 then '_ora10' end
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_process#java_binds;


procedure ut_process#java_hlp_methods1
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%java_hlp_methods1'
  );

  l_etalon := ftldb_api.default_template_loader(
    'ut_ftldb_api$process%java_hlp_methods1_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_process#java_hlp_methods1;


procedure ut_process#java_hlp_methods2
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%java_hlp_methods2_beg'
  );

  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%java_hlp_methods2_end'
  );


  l_etalon := ftldb_api.default_template_loader(
    'ut_ftldb_api$process%java_hlp_methods2_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_process#java_hlp_methods2;


procedure ut_process#standard
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%standard'
  );

  l_etalon := ftldb_api.default_template_loader(
    'ut_ftldb_api$process%standard_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_process#standard;


procedure ut_process#sql
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%sql'
  );

  l_etalon := ftldb_api.default_template_loader(
    'ut_ftldb_api$process%sql_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if;
end ut_process#sql;


end ut_ftldb_api;
/
