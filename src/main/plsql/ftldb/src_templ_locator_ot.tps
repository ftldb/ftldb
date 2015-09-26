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

create or replace type src_templ_locator_ot authid current_user
under templ_locator_ot (
/**
 * This type is a locator of a template stored in an Oracle object's source
 * either in a non-compiled PLSQLCC section or in a named section bounded by
 * special comment lines.
 *
 * The template name may start with 'src:' prefix. It may be any valid Oracle
 * function, procedure, package, type, trigger, view or java source name. It
 * must match the [SCHEMA.]OBJNAME[%SECNAME][@DBLINK] mask.
 *
 * The template name may also be a Java long name without a prefix.
 *
 * See {%link SOURCE_UTIL} package.
 * @headcom
 */

-- The template container's owner.
owner varchar2(30),

-- The template container's object name.
obj_name varchar2(30),

-- The template container's section name.
sec_name varchar2(30),

-- The template container's dblink.
dblink varchar2(128),

-- The template container's object type.
type varchar2(30),


/**
 * Creates a locator instance, resolves the template name and determines
 * the container object's attributes.
 *
 * @return  the template's locator
 */
static function new(
  in_templ_name in varchar2
) return src_templ_locator_ot,


/**
 * Loads the template's body from the container object's source.
 *
 * @return  the template's body
 */
overriding member function get_templ_body return clob,


/**
 * Gets the container object's timestamp.
 *
 * @return  the object's timestamp in 'YYYYMMDDHH24MISS' format
 */
overriding member function get_last_modified return integer


)
/
