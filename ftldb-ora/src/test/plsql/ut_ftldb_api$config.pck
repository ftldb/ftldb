--
-- Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy
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

create or replace package ut_ftldb_api$config is


function gen_ftldb_config_xml_func return ftldb_script_ot;


function drop_ftldb_config_xml_func return ftldb_script_ot;


function template_finder(in_templ_name varchar2) return varchar2;


function template_loader(in_locator in varchar2) return clob;


end ut_ftldb_api$config;
/
create or replace package body ut_ftldb_api$config is


function gen_ftldb_config_xml_func return ftldb_script_ot
is
begin
  return
    ftldb_api.process(
      $$plsql_unit || '%ftldb_config_xml',
      ftldb_varchar2_nt(sys_context('userenv', 'current_schema'), $$plsql_unit)
    );

$if null $then
--%begin ftldb_config_xml
<#assign schema = template_args[0]/>
<#assign package = template_args[1]/>

create or replace function ftldb_config_xml return xmltype
as
  c_pkg_name constant varchar2(70) :=
    '"${schema}"."${package}"';

  c_finder_func constant varchar2(100) :=
    c_pkg_name || '.template_finder';
  c_loader_func constant varchar2(100) :=
    c_pkg_name || '.template_loader';

  c_config constant varchar2(32767) :=
    '<?xml version="1.0" encoding="UTF-8"?>
    <java version="1.0" class="java.beans.XMLDecoder">
      <object class="ftldb.DefaultConfiguration">
        <void property="templateLoader">
          <object class="ftldb.oracle.DatabaseTemplateLoader">
            <string>' || utl_i18n.escape_reference(c_finder_func) || '</string>
            <string>' || utl_i18n.escape_reference(c_loader_func) || '</string>
          </object>
        </void>
        <void property="cacheStorage">
          <object class="freemarker.cache.NullCacheStorage"/>
        </void>
      </object>
    </java>';
begin
  return xmltype(c_config);
end ftldb_config_xml;
${"/"}

--%end ftldb_config_xml
$end

end;


function drop_ftldb_config_xml_func return ftldb_script_ot
is
begin
  return ftldb_script_ot('drop function ftldb_config_xml');
end;


function template_finder(in_templ_name varchar2) return varchar2
is
begin
   dbms_output.put_line('--TEST: user defined template finder -- OK');
   return ftldb_api.get_templ_locator_xmlstr(in_templ_name);
end;


function template_loader(in_locator in varchar2) return clob
is
begin
   dbms_output.put_line('--TEST: user defined template loader -- OK');
   return ftldb_api.get_templ_body(in_locator);
end;


end ut_ftldb_api$config;
/
