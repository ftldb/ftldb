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

create or replace package ftldb_api authid current_user as
/**
 * This package provides a public PL/SQL API for the FTLDB engine.
 * @headcom
 */


/**
 * Loads the template by its name.
 *
 * Resolves the template's name into an Oracle object, extracts a section from
 * its source and returns it as a template's body. If the name matches
 * [OWNER.]OBJNAME[@DBLINK] pattern, then the sought section is non-compiled.
 * If it matches [OWNER.]OBJNAME%SECNAME[@DBLINK] pattern, then the sought
 * section is named.
 *
 * @param  in_templ_name  the template's name
 * @return                the loaded template
 */
function default_template_loader(in_templ_name in varchar2) return clob;


/**
 * Initializes a new configuration for the FreeMarker engine. Sets the loader
 * for FTL templates from the database.
 *
 * @param  in_templ_loader  the stored PL/SQL function that is called by
 *                          ftldb.oracle.DBTemplateLoader class in order to get
 *                          a template from the database by its name; if not
 *                          set then {@link default_template_loader} is used
 */
procedure init(in_templ_loader in varchar2 := null);


/**
 * Processes the template with the specified name with the FreeMarker engine.
 *
 * @param  in_templ_name  the template's name
 * @param  in_templ_args  the template's arguments
 * @return                the processed template as a CLOB
 */
function process_to_clob(
  in_templ_name in varchar2,
  in_templ_args in varchar2_nt := varchar2_nt()
) return clob;


/**
 * Processes the specified template with the FreeMarker engine.
 *
 * @param  in_templ_body  the template's body
 * @param  in_templ_args  the template's arguments
 * @return                the processed template as a CLOB
 */
function process_body_to_clob(
  in_templ_body in clob,
  in_templ_args in varchar2_nt := varchar2_nt()
) return clob;


/**
 * Processes the template with the specified name with the FreeMarker engine.
 *
 * @param  in_templ_name  the template's name
 * @param  in_templ_args  the template's arguments
 * @param  in_stmt_delim  the delimiter for splitting the result into statements
 * @return                the processed template as a {@link script_ot} object
 */
function process(
  in_templ_name in varchar2,
  in_templ_args in varchar2_nt := varchar2_nt(),
  in_stmt_delim in varchar2 := '</>'
) return script_ot;


/**
 * Processes the specified template with the FreeMarker engine.
 *
 * @param  in_templ_body  the template's body
 * @param  in_templ_args  the template's arguments
 * @param  in_stmt_delim  the delimiter for splitting the result into statements
 * @return                the processed template as a {@link script_ot} object
 */
function process_body(
  in_templ_body in clob,
  in_templ_args in varchar2_nt := varchar2_nt(),
  in_stmt_delim in varchar2 := '</>'
) return script_ot;


end ftldb_api;
/
