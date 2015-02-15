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

function get_cur_view(in_tab_name varchar2) return clob;

procedure ut_dflt_templ_loader#proc;
procedure ut_dflt_templ_loader#sect;
procedure ut_dflt_templ_loader#exec;
procedure ut_dflt_templ_loader#args;

procedure ut_process#java_binds;
procedure ut_process#java_hlp_methods1;
procedure ut_process#java_hlp_methods2;
procedure ut_process#standard;
procedure ut_process#sql;


end ut_ftldb_api;
/
create or replace package body ut_ftldb_api is


function get_cur_view(in_tab_name varchar2) return clob
is
  l_clob clob;
begin
  select t.templ_body into l_clob
  from ut_ftldb_api$template$tab t
  where t.templ_name = in_tab_name;
  
  return l_clob;
end;


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
end;

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
end;

procedure ut_dflt_templ_loader#exec
is
  l_tmpl clob;
  l_etalon clob := 
    'create or replace view ${tab_name}_cur as' || chr(10) ||
    'select' || chr(10) ||
    '  t.*, t.rowid row_id' || chr(10) ||
    'from ${tab_name}_hist t' || chr(10) ||
    'where' || chr(10) ||
    '  t.dt_beg >= sysdate and sysdate < t.dt_end' || chr(10) ||
    '/';  
begin
  l_tmpl := ftldb_api.default_template_loader(
    'exec:ut_ftldb_api.get_cur_view(''templ_1'')'
  );
  
  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if; 
end;

procedure ut_dflt_templ_loader#args
is
  l_tmpl clob;
  l_etalon clob := 
    '<#assign template_args = {"x" : 10, "y" : "abc"} />' || chr(10) ||
    '  x = ${template_args["x"]?c}' || chr(10) ||
    '  y = ${template_args["y"]}' || chr(10);
begin
  /*
  --%begin ut_dflt_templ_loader#args
  x = ${template_args["x"]?c}
  y = ${template_args["y"]}
  --%end ut_dflt_templ_loader#args  
  */
  
  l_tmpl := ftldb_api.default_template_loader(
    'ut_ftldb_api%ut_dflt_templ_loader#args("x" : 10, "y" : "abc")'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if; 
end;


procedure ut_process#java_binds
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%java_binds'
  );

  l_etalon := ftldb_api.extract(
    'ut_ftldb_api$process%java_binds_res' ||
    case when dbms_db_version.version < 11 then '_ora10' end
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if; 
end;


procedure ut_process#java_hlp_methods1
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%java_hlp_methods1'
  );

  l_etalon := ftldb_api.extract(
    'ut_ftldb_api$process%java_hlp_methods1_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if; 
end;


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


  l_etalon := ftldb_api.extract(
    'ut_ftldb_api$process%java_hlp_methods2_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if; 
end;


procedure ut_process#standard
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%standard'
  );

  l_etalon := ftldb_api.extract(
    'ut_ftldb_api$process%standard_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if; 
end;


procedure ut_process#sql
is
  l_tmpl clob;
  l_etalon clob;
begin
  l_tmpl := ftldb_api.process_to_clob(
    'ut_ftldb_api$process%sql'
  );

  l_etalon := ftldb_api.extract(
    'ut_ftldb_api$process%sql_res'
  );

  if not nvl(dbms_lob.compare(l_tmpl, l_etalon) = 0, false) then
    ftldb_clob_util.show(l_tmpl);
    raise_application_error(-20000, 'Result is not as expected');
  end if; 
end;


end ut_ftldb_api;
/
