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
define grantee = "&2"

prompt Switch to &&ftldb_schema. schema.
alter session set current_schema = &&ftldb_schema.
/

prompt Create NUMBER_NT type.
@plsql/number_nt.typ
show errors type number_nt

prompt Create VARCHAR2_NT type.
@plsql/varchar2_nt.typ
show errors type varchar2_nt

prompt Create CLOB_NT type.
@plsql/clob_nt.typ
show errors type clob_nt

prompt Create CLOB_UTIL package.
@plsql/clob_util.pks
show errors package clob_util
@plsql/clob_util.pkb
show errors package body clob_util

prompt Create SCRIPT_OT type.
@plsql/script_ot.tps
show errors type script_ot
@plsql/script_ot.tpb
show errors type body script_ot

prompt Create SOURCE_UTIL package.
@plsql/source_util.pks
show errors package source_util
@plsql/source_util.pkb
show errors package body source_util

prompt Create FTLDB_WRAPPER package.
@plsql/ftldb_wrapper.pks
show errors package ftldb_wrapper

prompt Create FTLDB_API package.
@plsql/ftldb_api.pks
show errors package ftldb_api
@plsql/ftldb_api.pkb
show errors package body ftldb_api

prompt Create STANDARD_FTL package.
@plsql/standard_ftl.ftc
show errors package standard_ftl

prompt Create SQL_FTL package.
@plsql/sql_ftl.ftc
show errors package sql_ftl

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

prompt Grant execute privilege on PL/SQL objects to &&grantee..
/*
  It's absolutely safe to grant these privileges to PUBLIC due to
  the invoker-rights security approach.
*/
grant execute on number_nt to &&grantee.
/
grant execute on varchar2_nt to &&grantee.
/
grant execute on clob_nt to &&grantee.
/
grant execute on script_ot to &&grantee.
/
grant execute on standard_ftl to &&grantee.
/
grant execute on sql_ftl to &&grantee.
/
grant execute on source_util to &&grantee.
/
grant execute on clob_util to &&grantee.
/
grant execute on ftldb_wrapper to &&grantee.
/
grant execute on ftldb_api to &&grantee.
/

undefine ftldb_schema
undefine grantee
