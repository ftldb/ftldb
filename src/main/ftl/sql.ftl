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
<#--
-- This library contains functions and macros for working with SQL.
--->


<#--
-- Evaluates the specified SQL-compatible expression or function as a scalar
-- query, i.e select expr from dual. The returning type is automatically
-- determined.
--
-- @param  expr  the expression or the function's name
-- @param  args  the list of the function's parameters (optional)
-- @return       the result of the query as a scalar; if the function returns
--               REF CURSOR, the result is returned as a QueryResult object
--->
<#function select expr args...>
  <#local
    sql_statement = 'select ' + expr +
      args?has_content?string('('?right_pad(args?size*3 - 1, ' ?,') + ')', '') +
      ' from dual'
  />
  <#local res = default_connection().query(sql_statement, args).seq_rows/>
  <#if res[0][0]??>
    <#return res[0][0]/>
  <#else/>
    <#-- return null -->
  </#if>
</#function>


<#--
-- Converts the specified sequence to an SQL collection of the specified type.
--
-- @param  seq  the sequence to be converted to a collection
-- @param  typ  the collection's type (stored UDT)
-- @return      a collection of the specified type containing the sequence
--->
<#function collect seq typ>
  <#local
    sql_statement = 'select ' + typ + '(' +
      seq?has_content?string(''?right_pad(seq?size*3 - 2, '?, '), '') +
      ') from dual'
  />
  <#return default_connection().query(sql_statement, seq).seq_rows[0][0]/>
</#function>


<#--
-- Evaluates the specified PL/SQL expression or function. The returning type
-- must be provided as the first argument. Should be used instead of select
-- function when the expression or the function are incompatible with the pure
-- SQL (e.g. for accessing a package variable or passing/returning a boolean).
-- In contrast to Native Dynamic SQL you can call functions that have boolean
-- arguments; the sys.diutil package is used for bool2int/int2bool convertion.
--
-- @param  typ   the returning type, which is a constant from java.sql.Types or
--               oracle.jdbc.OracleTypes (in the latter case specified with the
--               full namespace), e.g. NUMERIC or oracle.jdbc.OracleTypes.CURSOR
-- @param  expr  the expression or the function's name
-- @param  args  the list of the function's parameters (optional)
-- @return       the result of the evaluation
--->
<#function eval typ expr args...>
  <#local is_bool_ret = (typ == 'BOOLEAN')/>
  <#local callable_statement = expr/>
  <#list args as arg>
    <#local
      callable_statement = callable_statement +
        (arg_index == 0)?string('(', '') +
        arg?is_boolean?string('sys.diutil.int_to_bool(?)', '?') +
        arg_has_next?string(', ', ')')
    />
  </#list>
  <#local
    callable_statement = '{? = call ' +
      is_bool_ret?string('sys.diutil.bool_to_int(', '') + callable_statement +
      is_bool_ret?string(')', '') + '}'
  />
  <#local binds = {}/>
  <#list args as arg>
    <#if arg?is_boolean>
      <#local val = arg?string('1', '0')?number/>
    <#else/>
      <#local val = arg/>
    </#if>
    <#local binds = binds + {(arg_index + 2)?c : val}/>
  </#list>
  <#local
    res = default_connection().exec(
      callable_statement, binds, {'1' : is_bool_ret?string("NUMERIC", typ)}
    )
  />
  <#if res['1']??>
    <#if is_bool_ret>
      <#return (res['1'] == 1)/>
    <#else/>
      <#return res['1']/>
    </#if>
  <#else/>
    <#-- return null -->
  </#if>
</#function>


<#--
-- Fetches the cursor returned by the specified function. This is a convenience
-- method for eval("oracle.jdbc.OracleTypes.CURSOR", cursor_func, args...).
--
-- @param  cursor_func  the function's name
-- @param  args         the list of the function's parameters (optional)
-- @return              the result as a QueryResult object
--->
<#function fetch cursor_func args...>
  <#local ftl_call = 'eval("oracle.jdbc.OracleTypes.CURSOR", cursor_func'/>
  <#list args as arg>
    <#local ftl_call = ftl_call + ', args[' + arg_index?c + ']'/>
  </#list>
  <#local ftl_call = ftl_call + ')'/>
  <#return ftl_call?eval/>
</#function>


<#--
-- Extracts the specified column from the specified QueryResult object, which
-- is represented as a row set (using .hash_rows or .seq_rows). May be useful
-- if your function returns a row set, but you need to use its single column as
-- a simple sequence. The resulting sequence doesn't contain null elements.
--
-- @param  row_set  the QueryResult object, represented as a row set
-- @param  column   the name or the index (from 0) of the column
-- @return          the column as a sequence
--->
<#function get_column row_set column>
  <#local seq = []/>
  <#list row_set as row>
    <#if row[column]??>
      <#local seq = seq + [row[column]]/>
    </#if>
  </#list>
  <#return seq/>
</#function>
