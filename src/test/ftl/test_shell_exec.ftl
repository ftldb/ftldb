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
<#assign res = shell_exec("java -version")/>
run "java -version":
<#list res.stderr as line>
${line}
</#list>

<#assign res = shell_exec(["java", "-version"])/>
run "java -version" as an array of parameters:
<#list res.stderr as line>
${line}
</#list>

<#assign res = shell_exec("java -version", "UTF-8")/>
run "java -version" with explicit encoding:
<#list res.stderr as line>
${line}
</#list>

<#assign res = shell_exec(["java", "-version"], "UTF-8")/>
run "java -version" as an array of parameters with explicit encoding:
<#list res.stderr as line>
${line}
</#list>

<#assign os = static("java.lang.System").getProperty("os.name")/>
<#if os?lower_case?contains("win")>
  <#assign res = shell_exec("cmd /c dir /b")/>
<#else/>
  <#assign res = shell_exec("ls -1")/>
</#if>
list current dir files:
<#list res.stdout as line>
${line}
</#list>
-- ${template_name()} END --
