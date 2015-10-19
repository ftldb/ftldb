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

-- Run as SYS, SYSTEM or any other superuser with the DBA privilege.
define user = "&1"       -- FTLDB schema name
define logfile = "&2"    -- Log file name

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

prompt Drop &&user. schema.
drop user &&user. cascade
/

prompt SQL*Plus script finished.

spool off

exit
