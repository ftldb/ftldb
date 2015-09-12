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
<@template name = "ftldb/test_shared_hash1.ftl"/>
-- ${template_name()} START --
Passed arguments:
<#list template_args as arg>
  arg[${arg?index}] = "${arg}"
</#list>

Save them to the shared hash as the key "v".
<#assign void = shared_hash.put("v", template_args)>
-- ${template_name()} END --
