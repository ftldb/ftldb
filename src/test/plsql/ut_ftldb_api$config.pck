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

create or replace package ut_ftldb_api$config is


function gen_ftldb_config_xml_func return ftldb_script_ot;


function drop_ftldb_config_xml_func return ftldb_script_ot;


procedure template_resolver(
  in_templ_name in varchar2,
  out_owner out varchar2,
  out_name out varchar2,
  out_sec_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
);


procedure template_loader(
  in_owner in varchar2,
  in_name in varchar2,
  in_sec_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2,
  out_body out clob
);


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
  l_pkg_name varchar2(70) :=
    '"${schema}"."${package}"';

  l_resolver_call varchar2(4000) :=
    '{call ' || l_pkg_name || '.template_resolver(?, ?, ?, ?, ?, ?)}';
  l_loader_call varchar2(4000) :=
    '{call ' || l_pkg_name || '.template_loader(?, ?, ?, ?, ?, ?)}';

  l_config varchar2(32767) :=
    '<?xml version="1.0" encoding="UTF-8"?>
    <java version="1.0" class="java.beans.XMLDecoder">
      <object class="ftldb.DefaultConfiguration">
        <void property="templateLoader">
          <object class="ftldb.oracle.DatabaseTemplateLoader">
            <string>' || utl_i18n.escape_reference(l_resolver_call) || '</string>
            <string>' || utl_i18n.escape_reference(l_loader_call) || '</string>
          </object>
        </void>
        <void property="cacheStorage">
          <object class="freemarker.cache.NullCacheStorage"/>
        </void>
      </object>
    </java>';
begin
  return xmltype(l_config);
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


procedure template_resolver(
  in_templ_name in varchar2,
  out_owner out varchar2,
  out_name out varchar2,
  out_sec_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
)
is
begin
   dbms_output.put_line('--TEST: user defined template resolver -- OK');
   ftldb_api.default_template_resolver(
     in_templ_name, out_owner, out_name, out_sec_name, out_dblink, out_type
   );
end;


procedure template_loader(
  in_owner in varchar2,
  in_name in varchar2,
  in_sec_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2,
  out_body out clob
)
is
begin
   dbms_output.put_line('--TEST: user defined template loader -- OK');
   ftldb_api.default_template_loader(
     in_owner, in_name, in_sec_name, in_dblink, in_type, out_body
   );
end;


end ut_ftldb_api$config;
/
