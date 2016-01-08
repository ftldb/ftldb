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

define ftldb_schema = "&1"
define action = "&2"
define grantee = "&3"

prompt Switch execute privileges on FTLDB objects for &&grantee.: &&action..
begin
  &&ftldb_schema..ftldb_admin.&&action._privileges('&&grantee.');
end;
/

undefine ftldb_schema
undefine action
undefine grantee
