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
<@template name = "@ftldb/std.ftl"/>
<#--
-- This library contains standard functions and macros for usual purposes.
-->


<#-- The default TAB size (the number of spaces) -->
<#assign DEFAULT_TAB_SIZE = 2/>


<#--
-- Returns the actual TAB size redefined by the global TAB_SIZE variable.
--
-- @return  the actual TAB size
-->
<#function tab_size>
  <#return .globals.TAB_SIZE!DEFAULT_TAB_SIZE/>
</#function>


<#--
-- Returns the least of one or more expressions.
--
-- @param  x  the first expression (mandatory)
-- @param  v  the rest of expressions (optional)
-- @return    the least value
-->
<#function least x v...>
  <#local res = x/>
  <#list v as y>
    <#if (y < res)>
      <#local res = y/>
    </#if>
  </#list>
  <#return res/>
</#function>


<#--
-- Returns the greatest of one or more expressions.
--
-- @param  x  the first expression (mandatory)
-- @param  v  the rest of expressions (optional)
-- @return    the greatest value
-->
<#function greatest x v...>
  <#local res = x/>
  <#list v as y>
    <#if (y > res)>
      <#local res = y/>
    </#if>
  </#list>
  <#return res/>
</#function>


<#--
-- Removes spaces from the left end of the specified string.
--
-- @param  str  the string to be trimmed
-- @return      the trimmed string
-->
<#function ltrim str>
  <#return str?replace('^\\s*', '', 'r')/>
</#function>


<#--
-- Removes spaces from the right end of the specified string.
--
-- @param  str  the string to be trimmed
-- @return      the trimmed string
-->
<#function rtrim str>
  <#return str?replace('\\s*$', '', 'r')/>
</#function>


<#--
-- Formats the elements of the specified sequence and concatenates them using
-- the specified delimiter.
--
-- @param  seq     the sequence to be concatenated
-- @param  format  the format mask of a sequence element
-- @param  delim   the delimiter
-- @param  token   the placeholder for a sequence element in the format mask
-- @return         the list of the sequence elements
--->
<#function to_list
  seq
  format = '%'
  delim = ', '
  token = '%'
>
  <#local lst = ''/>
  <#list seq as it>
    <#local lst += format?replace(token, it) + it?has_next?then(delim, '')/>
  </#list>
  <#return lst/>
</#function>


<#--
-- Indents the content with the specified shift.
--
-- @param  lshift  the number of left shifts (one space)
-- @param  rshift  the number of right shifts (one space)
-- @param  ltab    the number of left tabs
-- @param  rtab    the number of right tabs
-->
<#macro indent
  lshift = 0
  rshift = 0
  ltab = 0
  rtab = 0
>
  <#local output = ''/>
  <#local indent_width = (rshift - lshift) + (rtab - ltab)*tab_size()/>
  <#local content><#nested/></#local>
  <#list content?split('\n') as it>
    <#if it?has_next || (it?trim != '')>
      <#if (indent_width >= 0)>
        <#local
           output += ''?right_pad(indent_width) + it +
             it?has_next?then('\n', '')
        />
      <#else/>
        <#local
           output +=
             it?replace('^ {1,' + (-indent_width)?c + '}', '', 'r') +
             it?has_next?then('\n', '')
        />
      </#if>
    </#if>
  </#list>
  <#t/>${output}
</#macro>


<#--
-- Formats the content as a list of elements separated by a delimiter.
--
-- @param  split_ptrn      the regexp pattern for splitting the list into
--                         elements
-- @param  delim           the new delimiter
-- @param  trailing_delim  if true puts the delimiter at the end of the list
-- @param  max_len         the maximum line length
-- @param  keep_indent     if true puts the indent of the first line before
--                         each of the rest lines (the indent may changed by
--                         setting the following parameters)
-- @param  lshift          the number of left shifts (one space)
-- @param  rshift          the number of right shifts (one space)
-- @param  ltab            the number of left tabs
-- @param  rtab            the number of right tabs
-->
<#macro format_list
  split_ptrn = '\\s*,\\s*'
  delim = ', '
  trailing_delim = false
  max_len = 80
  keep_indent = true
  lshift = 0
  rshift = 0
  ltab = 0
  rtab = 0
>
  <#local output = ''/>
  <#local len = 0/>
  <#local delim_rt = rtrim(delim)/>
  <#local delim_ws = ''?right_pad(delim?length - delim_rt?length)/>
  <#local content><#nested/></#local>
  <#local
    indent = ''?right_pad(
      greatest(
        keep_indent?then(content?matches('^ *')[0]?length, 0) +
          (rshift - lshift) + (rtab - ltab)*tab_size(),
        0
      )
    )
  />
  <#list content?trim?split(split_ptrn, 'ri') as it>
    <#local str = it + (it?has_next || trailing_delim)?then(delim_rt, '')/>
    <#if (len == 0) || ((str + delim_ws)?length <= max_len - len)>
      <#local str = (it?index == 0)?then(indent, delim_ws) + str/>
      <#local len += str?length/>
    <#else>
      <#local str = '\n' + keep_indent?then(indent, '') + str/>
      <#local len = str?length - 1/>
    </#if>
    <#local output += str/>
  </#list>
  <#lt/>${output}
</#macro>


<#--
-- Includes the specified template passing the specified arguments to it. This
-- macro should be used instead of the built-in #include directive for including
-- parameterized templates that use the "template_args" shared variable inside.
--
-- @param  name            the template name
-- @param  args            the sequence of arguments
-- @param  ignore_missing  if true doesn't throw an exception when the template
--                         is not found, otherwise does
-- @param  parse           if true processes the template, otherwise only prints
-- @param  encoding        overrides the encoding of the top-level template
-->
<#macro include
  name
  args = []
  ignore_missing = false
  parse = true
  encoding = ''
>
  <#local template_args = args/>
  <#if encoding == ''>
    <#include
      name
      ignore_missing = ignore_missing
      parse = parse
    />
  <#else/>
    <#include
      name
      ignore_missing = ignore_missing
      parse = parse
      encoding = encoding
    />
  </#if>
</#macro>
