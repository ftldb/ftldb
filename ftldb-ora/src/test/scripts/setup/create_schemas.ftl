<#--

    Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

-->
prompt Define default tablespace.
column tbs noprint new_value default_tablespace
select p.property_value tbs
from database_properties p
where p.property_name = 'DEFAULT_PERMANENT_TABLESPACE'
/

<#macro create_schema schema pswd>
prompt Drop ${schema?upper_case} schema if exists.
declare
  l_exists number;
begin
  select
    case
      when exists(
        select * from all_users where username = upper('${schema}')
      )
      then 1
    end
  into l_exists
  from dual;
  if l_exists = 1 then
    execute immediate 'drop user ${schema} cascade';
  end if;
end;
/

prompt Create ${schema?upper_case} schema.
create user ${schema}
identified by "${pswd}"
default tablespace &&default_tablespace.
quota unlimited on &&default_tablespace.
/

prompt Grant system privileges to ${schema?upper_case} schema.
grant create session, debug connect session, create table, create view,
create trigger, create procedure, create type, create synonym, create database
link, create sequence
to ${schema}
/

prompt Grant Java permissions to ${schema?upper_case} schema.
begin
  dbms_java.grant_permission(
    upper('${schema}'), 'SYS:java.lang.RuntimePermission', 'getClassLoader', ''
  );
end;
/

prompt Grant execute privileges on FTLDB to ${schema?upper_case} schema.
begin
  ${ftldb_schema}.ftldb_admin.grant_privileges('${schema}');
end;
/

</#macro>

<@create_schema demo_schema "&&demo_pswd."/>
<@create_schema demo_schema+"_ext1" "&&demo_pswd."/>
<@create_schema demo_schema+"_ext2" "&&demo_pswd."/>
