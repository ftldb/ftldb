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

create or replace package ftldb_admin authid definer as
/**
 * This package grants/revokes privileges on FTLDB objects.
 * @headcom
 */


-- The list of grantable PL/SQL units
gc_grantable_plsql_units constant varchar2_nt := varchar2_nt(
  'FTLDB_WRAPPER', 'FTLDB_API', 'CLOB_UTIL', 'SOURCE_UTIL',  --packages
  'NUMBER_NT', 'VARCHAR2_NT', 'CLOB_NT',                     --collection types
  'SCRIPT_OT', 'TEMPL_LOCATOR_OT', 'SRC_TEMPL_LOCATOR_OT'    --object types
);


-- The list of grantable Java packages (including subpackages)
gc_grantable_java_packages constant varchar2_nt := varchar2_nt(
  'freemarker', 'ftldb'
);


/**
 * Grants privileges on FTLDB objects to the specified user.
 *
 * @param  in_grantee  the grantee name
 */
procedure grant_privileges(in_grantee in varchar2);


/**
 * Grants privileges on FTLDB objects to the specified list of users.
 *
 * @param  in_grantees  the grantee name list
 */
procedure grant_privileges(in_grantees in varchar2_nt);


/**
 * Revokes privileges on FTLDB objects from the specified user.
 *
 * @param  in_grantee  the grantee name
 */
procedure revoke_privileges(in_grantee in varchar2);


/**
 * Revokes privileges on FTLDB objects from the specified list of users.
 *
 * @param  in_grantee  the grantee name list
 */
procedure revoke_privileges(in_grantees in varchar2_nt);


end ftldb_admin;
/
