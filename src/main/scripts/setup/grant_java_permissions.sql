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

define grantee = "&1"

/*
  Since v2.3.21 FreeMarker has needed getClassLoader runtime permission.

  The Java API Specification reads:
    "This would grant an attacker permission to get the class loader for
    a particular class. This is dangerous because having access to a class's
    class loader allows the attacker to load other classes available to that
    class loader. The attacker would typically otherwise not have access to
    those classes."

  It's quite safe to grant this permission to PUBLIC, but if you consider it 
  crucial, grant it only to the users who work with FTLDB.
*/
prompt Grant "getClassLoader" Java runtime permission to &&grantee..
begin
  dbms_java.grant_permission(
    grantee => upper('&&grantee.'),
    permission_type => 'SYS:java.lang.RuntimePermission',
    permission_name => 'getClassLoader',
    permission_action => ''
  );
end;
/

undefine grantee
 