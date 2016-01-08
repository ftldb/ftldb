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

create or replace package body ftldb_api as


/**
 * Returns the owner of this package.
 */
function get_this_schema return varchar2
is
  l_owner varchar2(30 byte);
  l_name varchar2(30 byte);
  l_line number;
  l_type varchar2(30 byte);
begin
  owa_util.who_called_me(l_owner, l_name, l_line, l_type);
  return l_owner;
end get_this_schema;


/**
 * This is a locator factory method. It takes a template name and creates
 * a locator of the corresponding type.
 */
function new_templ_locator(in_templ_name in varchar2) return templ_locator_ot
is
begin
  case
    when in_templ_name like '_%' then
      return src_templ_locator_ot.new(in_templ_name);
    else
      return null;
  end case;
end new_templ_locator;


function get_templ_locator_xmlstr(in_templ_name in varchar2) return varchar2
is
  c_locator constant templ_locator_ot := new_templ_locator(in_templ_name);
begin
  if c_locator is null then
    return null;
  end if;

  return c_locator.xml_encode().getstringval();
end get_templ_locator_xmlstr;


function get_templ_body(in_locator_xmlstr in varchar2) return clob
is
begin
  return
    templ_locator_ot
      .xml_decode(xmltype(in_locator_xmlstr))
      .get_templ_body();
end get_templ_body;


function get_templ_last_modified(in_locator_xmlstr in varchar2) return integer
is
begin
  return
    templ_locator_ot
      .xml_decode(xmltype(in_locator_xmlstr))
      .get_last_modified();
end get_templ_last_modified;


function default_config_xml return xmltype
is
  c_pkg_name constant varchar2(65 byte) :=
    '"' || get_this_schema() || '"."' || $$plsql_unit || '"';

  c_finder_func_name constant varchar2(98 byte) :=
    c_pkg_name || '.get_templ_locator_xmlstr';
  c_loader_func_name constant varchar2(98 byte) :=
    c_pkg_name || '.get_templ_body';
  c_checker_func_name constant varchar2(98 byte) :=
    c_pkg_name || '.get_templ_last_modified';

  c_mru_strong_ref_count constant pls_integer := 20;
  c_mru_soft_ref_count constant pls_integer := 200;

  c_config constant varchar2(32767 byte) :=
    '<?xml version="1.0" encoding="UTF-8"?>
    <java version="1.4.0" class="java.beans.XMLDecoder">
      <object class="ftldb.DefaultConfiguration">
        <void property="templateLoader">
          <object class="ftldb.oracle.DatabaseTemplateLoader">
            <string>' ||
              utl_i18n.escape_reference(c_finder_func_name) ||
            '</string>
            <string>' ||
              utl_i18n.escape_reference(c_loader_func_name) ||
            '</string>
            <string>' ||
              utl_i18n.escape_reference(c_checker_func_name) ||
            '</string>
          </object>
        </void>
        <void property="cacheStorage">
          <object class="freemarker.cache.MruCacheStorage">
            <int>' || c_mru_strong_ref_count || '</int>
            <int>' || c_mru_soft_ref_count || '</int>
          </object>
        </void>
      </object>
    </java>';
begin
  return xmltype(c_config);
end default_config_xml;


function get_config_func_name return varchar2
is
  c_custom_config_func_name constant varchar2(98 byte) := 'ftldb_config_xml';
  c_default_config_func_name constant varchar2(98 byte) :=
    '"' || get_this_schema() || '"."' || $$plsql_unit || '"' ||
    '.default_config_xml';
begin
  return dbms_assert.sql_object_name(c_custom_config_func_name);
exception
  when dbms_assert.invalid_object_name then
    return c_default_config_func_name;
end get_config_func_name;


procedure init(in_config_xml in xmltype)
is
begin
  ftldb_wrapper.set_configuration(in_config_xml.getclobval());
end init;


procedure init(in_config_func_name in varchar2)
is
  l_config_xml xmltype;
begin
  execute immediate
    'begin' ||
    ' :1 := ' || dbms_assert.sql_object_name(in_config_func_name) || '; ' ||
    'end;'
  using out l_config_xml;

  init(l_config_xml);
end init;


procedure init
is
begin
  init(get_config_func_name());
end init;


function process_to_clob(
  in_templ_name in varchar2,
  in_templ_args in varchar2_nt := varchar2_nt()
) return clob
is
  l_result clob := clob_util.create_temporary();
begin
  ftldb_wrapper.set_arguments(in_templ_args);
  ftldb_wrapper.process(in_templ_name, l_result);
  return l_result;
end process_to_clob;


function process_body_to_clob(
  in_templ_body in clob,
  in_templ_args in varchar2_nt := varchar2_nt()
) return clob
is
  l_result clob := clob_util.create_temporary();
begin
  ftldb_wrapper.set_arguments(in_templ_args);
  ftldb_wrapper.process_body(in_templ_body, l_result);
  return l_result;
end process_body_to_clob;


function process(
  in_templ_name in varchar2,
  in_templ_args in varchar2_nt := varchar2_nt()
) return script_ot
is
begin
  return script_ot(process_to_clob(in_templ_name, in_templ_args));
end process;


function process_body(
  in_templ_body in clob,
  in_templ_args in varchar2_nt := varchar2_nt()
) return script_ot
is
begin
  return script_ot(process_body_to_clob(in_templ_body, in_templ_args));
end process_body;


function get_version return varchar2
is
begin
  return ftldb_wrapper.get_version();
end get_version;


function get_version_number return integer
is
begin
  return ftldb_wrapper.get_version_number();
end get_version_number;


function get_freemarker_version return varchar2
is
begin
  return ftldb_wrapper.get_freemarker_version();
end get_freemarker_version;


function get_freemarker_version_number return integer
is
begin
  return ftldb_wrapper.get_freemarker_version_number();
end get_freemarker_version_number;


begin
  init();
exception
  when others then
    dbms_session.modify_package_state(dbms_session.reinitialize);
    raise_application_error(
      -20000,
      'FTLDB initialization failed' || chr(10) ||
      dbms_utility.format_error_stack() ||
      dbms_utility.format_error_backtrace()
    );
end ftldb_api;
/
