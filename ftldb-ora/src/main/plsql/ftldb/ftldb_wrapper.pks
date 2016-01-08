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

create or replace package ftldb_wrapper authid current_user as
/**
 * This package wraps FTLDB Java API for PL/SQL usage.
 * @headcom
 */


procedure set_configuration(in_config_xml in clob)
is
language java name 'ftldb.oracle.Configurator.setConfiguration(java.sql.Clob)';


procedure set_configuration_setting(
  in_setting_name in varchar2,
  in_setting_value in varchar2
)
is
language java name 'ftldb.oracle.Configurator.setConfigurationSetting(java.lang.String, java.lang.String)';


procedure drop_configuration
is
language java name 'ftldb.oracle.Configurator.dropConfiguration()';


function get_version return varchar2
is
language java name 'ftldb.oracle.Configurator.getVersionString() return java.lang.String';


function get_version_number return number
is
language java name 'ftldb.oracle.Configurator.getVersionNumber() return int';


function get_freemarker_version return varchar2
is
language java name 'ftldb.oracle.Configurator.getFreeMarkerVersionString() return java.lang.String';


function get_freemarker_version_number return number
is
language java name 'ftldb.oracle.Configurator.getFreeMarkerVersionNumber() return int';


procedure process(in_templ_name in varchar2, io_result in out clob)
is
language java name 'ftldb.oracle.TemplateProcessor.process(java.lang.String, java.sql.Clob[])';


procedure process_body(in_templ_body in clob, io_result in out clob)
is
language java name 'ftldb.oracle.TemplateProcessor.process(java.sql.Clob, java.sql.Clob[])';


procedure set_arguments(in_templ_args in varchar2_nt)
is
language java name 'ftldb.oracle.TemplateProcessor.setArguments(java.sql.Array)';


end ftldb_wrapper;
/
