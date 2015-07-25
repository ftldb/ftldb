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

Get DB Version.
<#assign
  result =
  conn.exec(
    "begin\n" +
    "  :1 := dbms_db_version.version;\n" +
    "  :2 := dbms_db_version.release;\n" +
    "end;",
    {"1" : 1},
    {"1" : "NUMERIC", "2" : "NUMERIC"}
  )
/>
DB version: ${result["1"] + "." + result["2"]}

Create UDT instance.
<#assign udt = conn.query("select sys.odcinumberlist(1,2,3) from dual").seq_rows[0][0]>

Create CLOB instance.
<#assign clob = conn.query("select to_clob('loooong text') from dual").seq_rows[0][0]>

Execute query with variety of bind variable types.
<#assign
  res = conn.query(
    "select :1 byte, :2 shrt, :3 int, :4 lngint, :5 flt, :6 dbl, :7 bigdec, " +
    " :8 + 1/7 dt, :9 tmstmp, :10 str, :11 bool, :12 udt, :13 clob from dual",
    [
    1?byte, 1?short, 1?int, 1?long, 1.2?float, 1.2?double, 1.56,
    "31.03.2055"?date["dd.MM.yyyy"],
    "31.03.2012 17:23:39.544"?datetime["dd.MM.yyyy HH:mm:ss.SSS"],
    "text", true, udt, clob
    ]
  )
/>

Print columns and their corresponding SQL types:
  <#list res.col_meta_seq as currCol>
  ${currCol.name}: ${currCol.typeName}
  </#list>

How vales are returned:
  <#assign r = res.hash_rows[0]>
  byte = ${r.BYTE?c}
  short = ${res.hash_rows[0].SHRT?c}
  int = ${res.hash_rows[0].INT?c}
  longint = ${res.hash_rows[0].LNGINT?c}
  float = ${res.hash_rows[0].FLT?c}
  double = ${res.hash_rows[0].DBL?c}
  numeric = ${res.hash_rows[0].BIGDEC?c}
  date = ${res.hash_rows[0].DT?string["dd.MM.yyyy HH:mm:ss"]}
  timestamp returned as datetime? = ${res.hash_rows[0].TMSTMP?is_unknown_date_like?c}
  timestamp returned as string? = ${res.hash_rows[0].TMSTMP?is_string?c}
  timestamp = ${res.hash_rows[0].TMSTMP}
  string = ${res.hash_rows[0].STR}
  boolean returned as int? = ${res.hash_rows[0].BOOL?is_number?c}
  boolean = ${res.hash_rows[0].BOOL?c}
  udt = [<#list res.hash_rows[0].UDT as i>${i}<#sep>, </#list>]
  clob = ${res.hash_rows[0].CLOB}

Create UDT2 instance.
<#assign udt2 = conn.query("select sys.odcivarchar2list('a', 'b', 'c') from dual").seq_rows[0][0]>

Execute call with variety of bind variable types.
<#assign
  res = conn.exec(
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
    "  open v5 for select sysdate+rownum dt from dual connect by rownum <= 5;\n" +
    "  :9 := v5;\n" +
    "end;",
    {"1" : 1, "2" : "abc", "3" : "12.02.2000"?date["dd.MM.yyyy"], "4" : udt2},
    {"5" : "NUMERIC", "6" : "VARCHAR", "7" : "DATE", "8" : "ARRAY:SYS.ODCIVARCHAR2LIST",
     "9" : "oracle.jdbc.OracleTypes.CURSOR"}
  )
/>

Print result:
  number = ${res["5"]}
  string = ${res["6"]}
  date = ${res["7"]?string["dd.MM.yyyy"]}
  udt2 = [<#list res["8"] as i>'${i}'<#sep>, </#list>]
  cursor = {
    <#list res["9"].hash_rows as r>
    row_${r?index+1}: "DT" = ${r.DT}
    </#list>
  }

Create UDT3 instance.
<#assign udt3 = conn.query("select sys.odciobject('a', 'b') from dual").seq_rows[0][0]>
{
<#list udt3 as field>
  field#${field?index} : '${field}'<#sep>; </#sep>
</#list>
}
UDT3 is of ${udt3.getSQLTypeName()} type.

Close connection.
<#assign void = conn.close()/>
-- ${template_name()} END --
