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

define schema = "&1"
define pswd = "&2"

prompt Define default tablespace.
column tbs noprint new_value default_tablespace
select p.property_value tbs
from database_properties p
where p.property_name = 'DEFAULT_PERMANENT_TABLESPACE'
/

prompt Drop &&schema. schema if exists.
declare
  l_exists number;
begin
  select
    case
      when exists(
        select * from all_users where username = upper('&&schema.')
      )
      then 1
    end
  into l_exists
  from dual;
  if l_exists = 1 then
    execute immediate 'drop user &&schema. cascade';
  end if;
end;
/

prompt Create &&schema. schema.
create user &&schema.
identified by "&&pswd."
default tablespace &&default_tablespace.
quota unlimited on &&default_tablespace.
/

undefine schema
undefine pswd
