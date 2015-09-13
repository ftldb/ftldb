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

create or replace type src_template_locator_ot authid current_user as object (
/**
 * A locator of a template stored in an object's source.
 * @headcom
 */

-- The template's reference name.
templ_name varchar2(512),

-- The template's container owner.
owner varchar2(30),

-- The template's container object name.
obj_name varchar2(30),

-- The template's container section name.
sec_name varchar2(30),

-- The template's container dblink.
dblink varchar2(128),

-- The template's container object type.
type varchar2(30),


/**
 * Returns this class's name. Used for checking an XML for containing an object
 * of this type.
 *
 * @return  the name of this object type
 */
static function class return varchar2


)
/
