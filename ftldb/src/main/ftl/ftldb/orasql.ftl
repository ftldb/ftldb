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
<@template name = "@ftldb/orasql.ftl"/>
<#--
-- This library contains functions and macros for working with SQL.
--->


<#--
-- Executes the specified SQL query within the default connection. This is a
-- convenience method for default_connection().query(...).
--
-- @param  sql    the SQL query statement
-- @param  binds  the sequence of bind variable values
-- @return        the result set
--->
<#function query sql binds = []>
  <#return default_connection().query(sql, binds)/>
</#function>


<#--
-- Executes the specified PL/SQL call within the default connection. This is a
-- convenience method for default_connection().call(...).
--
-- @param  statement  the callable statement to be executed
-- @param  in_binds   the map of in bind variable indices to their values
-- @param  out_binds  the map of out bind variable indices to their type names
-- @return            a map of out bind variable indices to their values
--->
<#function call statement in_binds out_binds>
  <#return default_connection().call(statement, in_binds, out_binds)/>
</#function>


<#--
-- Evaluates the specified SQL-compatible expression or function as a scalar
-- query, i.e. select expr from dual. The returning type is automatically
-- determined.
--
-- @param  expr  the expression or the function's name
-- @param  args  the list of the function's parameters (optional)
-- @return       the result of the query as a scalar; if the function returns
--               REF CURSOR, the result is returned as a ResultSet object
--->
<#function scalar expr args>
  <#local
    sql_statement = 'select ' + expr +
      args?has_content?then('('?right_pad(args?size*3 - 1, ' ?,') + ')', '') +
      ' from dual'
  />
  <#local res = query(sql_statement, args)/>
  <#if res[0][0]??>
    <#return res[0][0]/>
  <#else/>
    <#-- return null -->
  </#if>
</#function>


<#--
-- Converts the specified sequence to an SQL collection of the specified type.
--
-- @param  typ  the collection's type (stored UDT)
-- @param  seq  the sequence to be converted to a collection
-- @return      a collection of the specified type containing the sequence
--->
<#function collect typ seq>
  <#local
    sql_statement = 'select ' + typ + '(' +
      seq?has_content?then(''?right_pad(seq?size*3 - 2, '?, '), '') +
      ') from dual'
  />
  <#return query(sql_statement, seq)[0][0]/>
</#function>


<#--
-- Evaluates the specified PL/SQL expression or function. The returning type
-- must be provided as the first argument. Should be used instead of 'scalar'
-- function when the expression or the function are incompatible with the pure
-- SQL (e.g. for accessing a package variable or passing/returning a boolean).
-- In contrast to Native Dynamic SQL you can call functions that have boolean
-- arguments; the sys.diutil package is used for bool2int/int2bool conversion.
--
-- @param  typ   the returning type, which is a constant from java.sql.Types or
--               oracle.jdbc.OracleTypes (in the latter case specified with the
--               full namespace), e.g. NUMERIC or oracle.jdbc.OracleTypes.CURSOR
-- @param  expr  the expression or the function's name
-- @param  args  the list of the function's parameters (optional)
-- @return       the result of the evaluation
--->
<#function eval typ expr args = []>
  <#local is_bool_ret = (typ == 'BOOLEAN')/>
  <#local callable_statement = expr/>
  <#list args as arg>
    <#local
      callable_statement +=
        (arg?index == 0)?then('(', '') +
        arg?is_boolean?then('sys.diutil.int_to_bool(?)', '?') +
        arg?has_next?then(', ', ')')
    />
  </#list>
  <#local
    callable_statement = '{? = call ' +
      is_bool_ret?then('sys.diutil.bool_to_int(', '') + callable_statement +
      is_bool_ret?then(')', '') + '}'
  />
  <#local binds = {}/>
  <#list args as arg>
    <#if arg?is_boolean>
      <#local val = arg?then(1, 0)/>
    <#else/>
      <#local val = arg/>
    </#if>
    <#local binds += {(arg?index + 2)?c : val}/>
  </#list>
  <#local
    res = call(
      callable_statement, binds, {'1' : is_bool_ret?then('NUMERIC', typ)}
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
-- @return              the result as a ResultSet object
--->
<#function fetch cursor_func args = []>
  <#return eval("oracle.jdbc.OracleTypes.CURSOR", cursor_func, args)/>
</#function>
