<#--

    Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy

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
<@template name = "@ftldb/include/mylib.ftl"/>

<#import "@ftldb/std.ftl" as std/>

<#macro include1 name>
######## including ${name} ########
  <@std.include name = name skip = 1/>
##########################################################
</#macro>

<#macro include2 name>
======== including ${name} ========
  <#local name = std.to_abs_name(name, 1)/>
  <#include name/>
==========================================================
</#macro>
