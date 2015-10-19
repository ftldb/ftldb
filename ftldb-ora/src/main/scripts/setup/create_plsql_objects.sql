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

define ftldb_schema = "&1"

prompt Switch to &&ftldb_schema. schema.
alter session set current_schema = &&ftldb_schema.
/

prompt Create NUMBER_NT type.
@plsql/ftldb/number_nt.typ
show errors type number_nt

prompt Create VARCHAR2_NT type.
@plsql/ftldb/varchar2_nt.typ
show errors type varchar2_nt

prompt Create CLOB_NT type.
@plsql/ftldb/clob_nt.typ
show errors type clob_nt

prompt Create CLOB_UTIL package.
@plsql/ftldb/clob_util.pks
show errors package clob_util
@plsql/ftldb/clob_util.pkb
show errors package body clob_util

prompt Create SCRIPT_OT type.
@plsql/ftldb/script_ot.tps
show errors type script_ot
@plsql/ftldb/script_ot.tpb
show errors type body script_ot

prompt Create TEMPL_LOCATOR_OT type.
@plsql/ftldb/templ_locator_ot.tps
show errors type templ_locator_ot
@plsql/ftldb/templ_locator_ot.tpb
show errors type body templ_locator_ot

prompt Create SOURCE_UTIL package.
@plsql/ftldb/source_util.pks
show errors package source_util
@plsql/ftldb/source_util.pkb
show errors package body source_util

prompt Create SRC_TEMPL_LOCATOR_OT type.
@plsql/ftldb/src_templ_locator_ot.tps
show errors type src_templ_locator_ot
@plsql/ftldb/src_templ_locator_ot.tpb
show errors type body src_templ_locator_ot

prompt Create FTLDB_WRAPPER package.
@plsql/ftldb/ftldb_wrapper.pks
show errors package ftldb_wrapper

prompt Create FTLDB_API package.
@plsql/ftldb/ftldb_api.pks
show errors package ftldb_api
@plsql/ftldb/ftldb_api.pkb
show errors package body ftldb_api

prompt Create FTLDB_ADMIN package.
@plsql/ftldb/ftldb_admin.pks
show errors package ftldb_admin
@plsql/ftldb/ftldb_admin.pkb
show errors package body ftldb_admin

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
    raise_application_error(-20000, 'Compilation errors detected.');
  end if;
  dbms_output.put_line('Compilation errors not detected.');
end;
/

undefine ftldb_schema
