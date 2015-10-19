<#--

    Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy

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
prompt Create additional objects in other schemas for Unit Tests.
<#include "@@../plsql/ut_source_util$resolve_name.ftl">

prompt Create UT_CLOB_UTIL package.
<#include "@@../plsql/ut_clob_util.pck">
show errors

prompt Create UT_SOURCE_UTIL package and additional objects.
<#include "@@../plsql/ut_source_util$long2clob$vw.sql">
show errors
<#include "@@../plsql/ut_source_util$extract_sect.pks">
show errors
<#include "@@../plsql/ut_source_util.pck">
show errors

prompt Create UT_SCRIPT_OT package.
<#include "@@../plsql/ut_script_ot.pck">
show errors

prompt Create UT_FTLDB_API package and additional objects.
<#include "@@../plsql/ut_ftldb_api$process.pks" parse=false>
show errors
<#include "@@../plsql/ut_ftldb_api$config.pck" parse=false>
show errors
<#include "@@../plsql/ut_ftldb_api.pck" parse=false>
show errors

prompt Check for compilation errors.
declare
  l_err_flg integer;
begin
  select
    case when exists(
      select e.* from all_errors e
      where e.owner = sys_context('userenv', 'current_schema')
    ) then 1
    end
  into l_err_flg
  from dual;
  if l_err_flg = 1 then
    raise_application_error(-20000, 'Compilation errors detected');
  end if;
  dbms_output.put_line('Compilation errors not detected.');
end;
/
