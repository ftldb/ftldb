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
<#import '@ftldb/std.ftl' as std>

-- ${template_name()} START --
Include another template @@test_included.ftl
<#include "@@test_included.ftl"/>

Include another template @@test_included_param.ftl with params: ['val1', 'val2']
<@std.include "@@test_included_param.ftl", ['val1', 'val2']/>

Include another template @@sub/test_included_param2.ftl with params: ['val3', 'val4']
<@std.include "@@sub/test_included_param2.ftl", ['val3', 'val4']/>

<#import '@ftldb/include/mylib.ftl' as my>
Include another template @@sub/test_included_param2.ftl with a custom macro 1:
<@my.include1 "@@sub/test_included_param2.ftl"/>

Include another template @@sub/test_included_param2.ftl with a custom macro 2:
<@my.include2 "@@sub/test_included_param2.ftl"/>

Absolute path of @@sub/test_included_param2.ftl:
  "${std.to_abs_name("@@sub/test_included_param2.ftl")}"
-- ${template_name()} END --
