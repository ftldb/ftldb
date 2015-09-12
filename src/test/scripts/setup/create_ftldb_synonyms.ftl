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
prompt Create synonyms for ${ftldb_schema} objects.
create or replace synonym ftldb_api for ${ftldb_schema}.ftldb_api
/
create or replace synonym ftldb_wrapper for ${ftldb_schema}.ftldb_wrapper
/
create or replace synonym ftldb_clob_util for ${ftldb_schema}.clob_util
/
create or replace synonym ftldb_source_util for ${ftldb_schema}.source_util
/
create or replace synonym ftldb_script_ot for ${ftldb_schema}.script_ot
/
create or replace synonym ftldb_number_nt for ${ftldb_schema}.number_nt
/
create or replace synonym ftldb_varchar2_nt for ${ftldb_schema}.varchar2_nt
/
create or replace synonym ftldb_clob_nt for ${ftldb_schema}.clob_nt
/
create or replace synonym ftldb_std_ftl for ${ftldb_schema}.std_ftl
/
create or replace synonym ftldb_orasql_ftl for ${ftldb_schema}.orasql_ftl
/
