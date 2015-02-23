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

-- Run as a user with the following privileges: CREATE TABLE,
-- CREATE PROCEDURE, CREATE TYPE, QUOTA on the default tablespace.
define logfile = "&1"    -- Log file name

set echo off
set verify off
set sqlblanklines on
set trimspool on
set termout on
set define on
set serveroutput on size unlimited format wrapped
whenever oserror exit failure
whenever sqlerror exit failure

spool &&logfile.

prompt SQL*Plus script started.

prompt Drop FTLDB objects.
drop package sql_ftl
/
drop package standard_ftl
/
drop package ftldb_api
/
drop package ftldb_wrapper
/
drop package source_util
/
drop package clob_util
/
drop type script_ot
/
drop type clob_nt
/
drop type varchar2_nt
/
drop type number_nt
/

prompt SQL*Plus script finished.

spool off

exit
