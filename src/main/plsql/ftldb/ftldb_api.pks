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
 * Default template finder. Passes an external call to a specific finder
 * depending on the template's name prefix. Returns an XML locator as a string.
 * If the search fails, returns null.
 *
 * @param  in_templ_name    the template's name
 * @param  out_locator_xml  the template's locator
 */
procedure default_template_finder(
  in_templ_name in varchar2,
  out_locator_xml out varchar2
);


/**
 * Default template loader. Passes an external call to a specific loader
 * depending on the template's locator. Returns the template's body.
 *
 * @param  in_locator_xml  the template's locator
 * @param  out_body        the loaded template as a CLOB
 */
procedure default_template_loader(
  in_locator_xml in varchar2,
  out_body out clob
);


/**
 * Default template checker. Passes an external call to a specific checker
 * depending on the template's locator. Returns the template's timestamp.
 *
 * @param  in_locator_xml  the template's locator
 * @param  out_millis      the template's age in milliseconds since Unix Epoch
 */
procedure default_template_checker(
  in_locator_xml in varchar2,
  out_millis out integer
);


/**
 * Source template finder. Seeks a template in stored objects' source. Returns
 * a SRC_TEMPLATE_LOCATOR_OT object.
 *
 * @param  in_templ_name  the template's name
 * @param  out_locator    the template's locator
 */
procedure source_template_finder(
  in_templ_name in varchar2,
  out_locator out src_template_locator_ot
);


/**
 * Source template loader. Loads a template from its container object's source.
 *
 * @param  in_locator  the template's locator
 * @param  out_body    the loaded template as a CLOB
 */
procedure source_template_loader(
  in_locator in src_template_locator_ot,
  out_body out clob
);


/**
 * Source template checker. Checks a template for its last modification time.
 *
 * @param  in_locator  the template's locator
 * @param  out_millis  the container object's milliseconds since Unix Epoch
 */
procedure source_template_checker(
  in_locator in src_template_locator_ot,
  out_millis out integer
);


/**
 * Returns the default configuration XML.
 *
 * Uses 'ftldb.oracle.DatabaseTemplateLoader' class as a template loader with
 * the default finder, loader and checker calls.
 * Uses 'freemarker.cache.MruCacheStorage' class as a cache storage with 20 hard
 * references and 200 soft references (actually Oracle cleans them immediately).
 *
 * @return  the configuration XML
 */
function default_config_xml return xmltype;


/**
 * Initializes a new configuration for the FreeMarker engine with the specified
 * XML in java.beans.XMLEncoder format.
 *
 * @param  in_config_xml  the configuration XML
 */
procedure init(in_config_xml in xmltype);


/**
 * Initializes a new configuration for the FreeMarker engine. Executes the
 * specified function, gets an XML configuration from it and sets it as the new
 * configuration.
 *
 * @param  in_config_func_name  the configuration function name, the function
 *                              must have no parameters and return XMLType
 */
procedure init(in_config_func_name in varchar2);


/**
 * Initializes a new configuration for the FreeMarker engine. Seeks a function
 * named FTLDB_CONFIG_XML and tries to get the XML configuration from it. If
 * the function is not found, uses the DEFAULT_CONFIG_XML function from this
 * package.
 */
procedure init;


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
 * @return                the processed template as a {@link script_ot} object
 */
function process(
  in_templ_name in varchar2,
  in_templ_args in varchar2_nt := varchar2_nt()
) return script_ot;


/**
 * Processes the specified template with the FreeMarker engine.
 *
 * @param  in_templ_body  the template's body
 * @param  in_templ_args  the template's arguments
 * @return                the processed template as a {@link script_ot} object
 */
function process_body(
  in_templ_body in clob,
  in_templ_args in varchar2_nt := varchar2_nt()
) return script_ot;


/**
 * Returns the FTLDB version as a string.
 *
 * @return FTLDB version
 */
function get_version return varchar2;


/**
 * Returns the FTLDB version as a comparable integer.
 *
 * @return FTLDB version
 */
function get_version_number return integer;


/**
 * Returns the FreeMarker version as a string.
 *
 * @return FreeMarker version
 */
function get_freemarker_version return varchar2;


/**
 * Returns the FreeMarker version as a comparable integer.
 *
 * @return FreeMarker version
 */
function get_freemarker_version_number return integer;


end ftldb_api;
/
