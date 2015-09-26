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

create or replace type templ_locator_ot authid current_user as object (
/**
 * This type is an abstract template locator.
 *
 * Its subtypes must be used for implementing different template loading
 * mechanisms. A concrete template locator must implement a factory method that
 * finds a template by its name and returns its locator or null if the template
 * is not found.
 * @headcom
 */

-- The template's name
templ_name varchar2(4000),


/**
 * Returns the full name of a tempalte locator instance subtype.
 *
 * @return  the subtype name as "SCHEMA"."NAME"
 */
member function get_type_name return varchar2,


/**
 * Serializes an instance of a template locator subtype to an XML object. Saves
 * its real type and content.
 *
 * @return  XML containing the template locator
 */
member function xml_encode return xmltype,


/**
 * Deserializes an XML object to an instance of a template locator subtype.
 *
 * @return  the original instance as an abstract template locator
 */
static function xml_decode(in_locator_xml xmltype) return templ_locator_ot,


/**
 * Loads the template's body from its location.
 *
 * @return  the template's body
 */
not instantiable member function get_templ_body return clob,


/**
 * Gets the last time of the template's modification. The timestamp may be in
 * any comparable digital format, e.g. Unix Epoch time or 'YYYYMMDDHH24MISSFF3'.
 *
 * @return  the template's timestamp as a comparable integer
 */
not instantiable member function get_last_modified return integer


)
not final
not instantiable
/
