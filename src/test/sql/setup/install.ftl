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
<#-- Define parameters -->

<#assign cnt = command_line_args?size - 1/>
<#if (cnt < 4)><#stop "Not enough parameters!"/></#if>

<#assign instance_tns_name = command_line_args[1]?upper_case/>
<#assign super_user = command_line_args[2]?upper_case/>
<#assign ftldb_schema = command_line_args[3]?upper_case/>
<#assign demo_schema = command_line_args[4]?upper_case/>

<#macro connect service user pswd>
prompt Connect as ${user?upper_case}.
connect ${user}/${pswd}@${service}<#if (user?lower_case == "sys")> as sysdba</#if>
</#macro>

<#macro set_current schema>
prompt Set ${schema?upper_case} as a current schema.
alter session set current_schema = ${schema}
/
</#macro>

define super_user_pswd = "&1"
define demo_pswd = "&2"
define logfile = "&3"

<#-- Set up SQL*Plus setting -->
set echo off
set verify off
set sqlblanklines on
set termout on
set define on
whenever oserror exit failure
whenever sqlerror exit failure

<@connect instance_tns_name super_user "&&super_user_pswd."/>

set serveroutput on size unlimited format wrapped

spool &&logfile.

prompt SQL*Plus script started.

<#-- (Re)create demo schema and additional test schemas -->
<#include "create_schemas.ftl"/>

<@set_current demo_schema/>

<#-- Create synonyms for FTLDB objects -->
<#include "create_ftldb_synonyms.ftl"/>

<#-- Create test packages and additional objects -->
<#include "create_test_objects.ftl"/>

<#-- Run tests -->
<#include "run_tests.sql"/>

<#-- Install demo -->
<#--include "demo"/-->

prompt SQL*Plus script finished.

spool off

exit
