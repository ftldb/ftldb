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
<@template name = "@ftldb/test_query_and_call.ftl"/>
-- ${template_name()} START --
Open connection.
<#import "@dbconn.config.ftl" as conf>
<#assign conn = conf.new_conn()/>


Fetch SQL collection from query.
<#assign coll = conn.query("select sys.odcinumberlist(1,2,3) from dual")[0][0]/>
Print SQL collection: [<#list coll as i>${i}<#sep>, </#list>]
SQL collection type: ${coll.SQLTypeName}
SQL collection base type: ${coll.baseTypeName}


Fetch CLOB from query.
<#assign clob = conn.query("select to_clob('loooong text') from dual")[0][0]/>
Print CLOB: "${clob}"
CLOB length: ${clob?length}


Fetch SQL structure (object type) from query.
<#assign struct = conn.query("select sys.odciobject('duck', 'goose') from dual")[0][0]/>
Print SQL structure: {<#list struct as i>field#${(i?index+1)?c} : "${i}"<#sep>, </#list>}
SQL structure type: ${struct.SQLTypeName}

--------------------------------------------------------------------------------

Execute query with variety of in-bind variables and fetch them back.
<#assign
  res = conn.query(
    "select :1 byte, :2 shrt, :3 int, :4 lngint, :5 flt, :6 dbl, :7 bigdec, " +
    " :8 + 1/7 dt, :9 tmstmp, :10 str, :11 bool, :12 coll, :13 struct, :14 clob from dual",
    [
    1?byte, 1?short, 1?int, 1?long, 1.2?float, 1.2?double, 1.56,
    "31.03.2055"?date["dd.MM.yyyy"], "31.03.2012 17:23:39.544"?datetime["dd.MM.yyyy HH:mm:ss.SSS"],
    "text", true, coll, struct, clob
    ]
  )
/>

Print columns and their corresponding SQL types:
{
<#list 1..res.metaData.columnCount as i>
  ${res.metaData.columnName(i)} : ${res.metaData.columnTypeName(i)}
</#list>
}

Print passed types and returned values.
<#assign r = res[0]/>
{
  byte : ${r.BYTE?c}
  short : ${r.SHRT?c}
  int : ${r.INT?c}
  longint : ${r.LNGINT?c}
  float : ${r.FLT?c}
  double : ${r.DBL?c}
  numeric : ${r.BIGDEC?c}
  date : ${r.DT?string["dd.MM.yyyy HH:mm:ss"]}
  timestamp : ${r.TMSTMP}
      timestamp is datetime? - ${r.TMSTMP?is_unknown_date_like?c}
      timestamp is string? - ${r.TMSTMP?is_string?c}
  string : ${r.STR}
  boolean : ${r.BOOL?c}
      boolean is int? - ${r.BOOL?is_number?c}
  collection = [<#list r.COLL as i>${i}<#sep>, </#list>]
  struct = {<#list r.STRUCT as i>field#${(i?index+1)?c} : "${i}"<#sep>, </#list>}
  clob = ${r.CLOB}
}

--------------------------------------------------------------------------------

Create SQL collection.
<#assign coll2 = conn.query("select sys.odcivarchar2list('a', 'b', 'c') from dual")[0][0]/>

Execute call with variety of in/out-bind variables.
<#assign
  res = conn.call(
    "declare\n" +
    "  v1 number := :1;\n" +
    "  v2 varchar2(200) := :2;\n" +
    "  v3 date := :3;\n" +
    "  v4 sys.odcivarchar2list := :4;\n" +
    "  v5 sys_refcursor;\n" +
    "begin\n" +
    "  :5 := v1 + 1;\n" +
    "  :6 := v2 || 'x';\n" +
    "  :7 := add_months(v3, 1);\n" +
    "  v4.extend(); v4(v4.last()) := 'd';\n" +
    "  :8 := v4;\n" +
    "  open v5 for select date'2015-03-01'+rownum dt from dual connect by rownum <= 5;\n" +
    "  :9 := v5;\n" +
    "end;",
    {"1" : 1, "2" : "abc", "3" : "12.02.2000"?date["dd.MM.yyyy"], "4" : coll2},
    {"5" : "NUMERIC", "6" : "VARCHAR", "7" : "DATE", "8" : "ARRAY:SYS.ODCIVARCHAR2LIST",
     "9" : "oracle.jdbc.OracleTypes.CURSOR"}
  )
/>

Print out bind variables:
{
  number : ${res["5"]}
  string : ${res["6"]}
  date : ${res["7"]?string["dd.MM.yyyy"]}
  collection : [<#list res["8"] as i>'${i}'<#sep>, </#list>]
  cursor : {
    <#list res["9"] as r>
    row#${(r?index+1)?c}: "DT" = ${r.DT?string["dd.MM.yyyy"]}
    </#list>
  }
}

--------------------------------------------------------------------------------

Execute query.
<#assign res = conn.query("select rownum n, 'row_' || rownum label from dual connect by level <= 5")/>
Print transposed result:
{
<#list res.transpose() as col>
  "${res.metaData.columnName(col?index+1)}" : [<#list col as val>${val}<#sep>, </#list>]
</#list>
}


Close connection.
<#assign void = conn.close()/>
-- ${template_name()} END --
