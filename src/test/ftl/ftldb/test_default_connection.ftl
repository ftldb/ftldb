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
<@template name = "ftldb/test_default_connection.ftl"/>
-- ${template_name()} START --
Open connection.
<#import "/dbconn.config.ftl" as conf>
<#assign conn = conf.new_conn()/>

Override default DB connection.
<@set_default_connection conn = conn/>

Execute query via default connection.
<#assign result = default_connection().query("select sys_context('userenv', 'db_name') db_name, sysdate dt from dual")/>

Print result:
${result}

Close connection.
<#assign void = conn.close()/>
-- ${template_name()} END --
