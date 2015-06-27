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
-- ${template_name()} START --
Open connection.
<#import "dbconn.config.ftl" as conf>
<#assign conn = conf.new_conn()/>

Execute query.
<#assign
  result = conn.query(
    "select level col1, 100 - level col2\n" +
    "from dual\n" +
    "connect by level < 10\n"
  )
/>

Print result:
${result}

Print columns in their order using .col_seq method:
<#list result.col_seq as col_arr>
  Column ${col_arr?index+1}:
  <#list col_arr as value>
	  row ${value?index+1}: ${value}
  </#list>
</#list>

Print the second column, then the first by their names using .col_hash method:
<#assign col_hash = result.col_hash/>
  COL2:
  <#list col_hash.COL2 as value>
    row ${value?index+1}: ${value}
  </#list>

  COL1:
  <#list col_hash.COL2 as value>
    row ${value?index+1}: ${value}
  </#list>

Close connection.
<#assign void = conn.close()/>
-- ${template_name()} END --
