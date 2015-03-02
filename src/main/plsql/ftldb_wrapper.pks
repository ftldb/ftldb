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

create or replace package ftldb_wrapper authid current_user as
/**
 * This package wraps Java API for the FTLDB engine.
 * @headcom
 */


procedure new_configuration
is
language java name 'ftldb.Configurator.newConfiguration()';


procedure set_db_template_loader(in_templ_loader_call in varchar2)
is
language java name 'ftldb.Configurator.setDBTemplateLoader(java.lang.String)';


procedure set_configuration_setting(
  in_setting_name in varchar2,
  in_setting_value in varchar2
)
is
language java name 'ftldb.Configurator.setConfigurationSetting(java.lang.String, java.lang.String)';


procedure drop_configuration
is
language java name 'ftldb.Configurator.dropConfiguration()';


function process(in_templ_name in varchar2) return clob
is
language java name 'ftldb.oracle.DBTemplateProcessor.process(java.lang.String) return java.sql.Clob';


function process_body(in_templ_body in clob) return clob
is
language java name 'ftldb.oracle.DBTemplateProcessor.processBody(java.sql.Clob) return java.sql.Clob';


procedure set_arguments(in_templ_args in varchar2_nt)
is
language java name 'ftldb.oracle.DBTemplateProcessor.setArguments(java.sql.Array)';


end ftldb_wrapper;
/
