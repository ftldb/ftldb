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

<#if (template_args?size < 3)><#stop "Not enough parameters!"/></#if>

<#assign instance_tns_name = template_args[0]?upper_case/>
<#assign super_user = template_args[1]?upper_case/>
<#assign demo_schema = template_args[2]?upper_case/>

<#macro connect service user pswd>
prompt Connect as ${user?upper_case}.
connect ${user}/${pswd}@${service}<#if (user?lower_case == "sys")> as sysdba</#if>
</#macro>

<#macro drop_schema schema>
prompt Drop schema ${schema?upper_case}.
drop user ${schema} cascade
/
</#macro>

define super_user_pswd = "&1"
define logfile = "&2"

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

<#-- Remove demo schema and additional test schemas -->
<@drop_schema demo_schema/>
<@drop_schema demo_schema+"_ext1"/>
<@drop_schema demo_schema+"_ext2"/>

prompt SQL*Plus script finished.

spool off

exit
