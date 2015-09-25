--
-- Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

create or replace package ut_ftldb_api$process as

$if null $then


--%begin args
  arg_num = ${template_args?size}
  <#list template_args as arg>
  arg_${arg?index} = ${arg}
  </#list>
--%end args


--%begin args_res
  arg_num = 3
  arg_0 = x
  arg_1 = y
  arg_2 = z
--%end args_res


--%begin java_binds
  <#assign conn = default_connection()/>
  <#assign ora_ver = conn.call("begin :1 := dbms_db_version.version; end;", {}, {"1" : "NUMERIC"})["1"]/>

  <#assign coll = conn.query("select sys.odcinumberlist(1,2,3) from dual")[0][0]/>
  coll = [<#list coll as i>${i}<#sep>, </#list>]
  type: ${coll.SQLTypeName}
  base type: ${coll.baseTypeName}

  <#assign clob = conn.query("select to_clob('loooong text') from dual")[0][0]/>
  clob = "${clob}"
  length: ${clob?length}

  <#assign struct = conn.query("select sys.odciobject('duck', 'goose') from dual")[0][0]/>
  struct = {<#list struct as i>field#${(i?index+1)?c} : "${i}"<#sep>, </#list>}
  type: ${struct.SQLTypeName}

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
  {
  <#list 1..res.metaData.columnCount as i>
    ${res.metaData.columnName(i)} : ${res.metaData.columnTypeName(i)}
  </#list>
  }

  <#assign r = res[0]/>
  {
    byte : ${r.BYTE?c}
    short : ${r.SHRT?c}
    int : ${r.INT?c}
    longint : ${r.LNGINT?c}
    float : <#if (ora_ver < 11)>*BINARY_VALUE*<#else/>${r.FLT?c}</#if>
    double : ${r.DBL?c}
    numeric : ${r.BIGDEC?c}
    date : ${r.DT?string["dd.MM.yyyy HH:mm:ss"]}
    timestamp : <#if (ora_ver < 11)>*JAVA_OBJ_REF*<#else/>${r.TMSTMP}</#if>
        timestamp is datetime? - ${r.TMSTMP?is_unknown_date_like?c}
        timestamp is string? - ${r.TMSTMP?is_string?c}
    string : ${r.STR}
    boolean : ${r.BOOL?c}
        boolean is int? - ${r.BOOL?is_number?c}
    collection = [<#list r.COLL as i>${i}<#sep>, </#list>]
    struct = {<#list r.STRUCT as i>field#${(i?index+1)?c} : "${i}"<#sep>, </#list>}
    clob = ${r.CLOB}
  }

  <#assign coll2 = conn.query("select sys.odcivarchar2list('a', 'b', 'c') from dual")[0][0]/>
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

  <#assign res = conn.query("select rownum n, 'row_' || rownum label from dual connect by level <= 5")/>
  {
  <#list res.transpose() as col>
    "${res.metaData.columnName(col?index+1)}" : [<#list col as val>${val}<#sep>, </#list>]
  </#list>
  }

--%end java_binds


--%begin java_binds_res
  coll = [1, 2, 3]
  type: SYS.ODCINUMBERLIST
  base type: NUMBER

  clob = "loooong text"
  length: 12

  struct = {field#1 : "duck", field#2 : "goose"}
  type: SYS.ODCIOBJECT

  {
    BYTE : NUMBER
    SHRT : NUMBER
    INT : NUMBER
    LNGINT : NUMBER
    FLT : NUMBER
    DBL : NUMBER
    BIGDEC : NUMBER
    DT : DATE
    TMSTMP : TIMESTAMP
    STR : VARCHAR2
    BOOL : NUMBER
    COLL : SYS.ODCINUMBERLIST
    STRUCT : SYS.ODCIOBJECT
    CLOB : CLOB
  }

  {
    byte : 1
    short : 1
    int : 1
    longint : 1
    float : 1.2
    double : 1.2
    numeric : 1.56
    date : 31.03.2055 03:25:43
    timestamp : 2012-03-31 17:23:39.544
        timestamp is datetime? - false
        timestamp is string? - true
    string : text
    boolean : 1
        boolean is int? - true
    collection = [1, 2, 3]
    struct = {field#1 : "duck", field#2 : "goose"}
    clob = loooong text
  }

  {
    number : 2
    string : abcx
    date : 12.03.2000
    collection : ['a', 'b', 'c', 'd']
    cursor : {
      row#1: "DT" = 02.03.2015
      row#2: "DT" = 03.03.2015
      row#3: "DT" = 04.03.2015
      row#4: "DT" = 05.03.2015
      row#5: "DT" = 06.03.2015
    }
  }

  {
    "N" : [1, 2, 3, 4, 5]
    "LABEL" : [row_1, row_2, row_3, row_4, row_5]
  }

--%end java_binds_res


--%begin java_binds_res_ora10
  coll = [1, 2, 3]
  type: SYS.ODCINUMBERLIST
  base type: NUMBER

  clob = "loooong text"
  length: 12

  struct = {field#1 : "duck", field#2 : "goose"}
  type: SYS.ODCIOBJECT

  {
    BYTE : NUMBER
    SHRT : NUMBER
    INT : NUMBER
    LNGINT : NUMBER
    FLT : NUMBER
    DBL : NUMBER
    BIGDEC : NUMBER
    DT : DATE
    TMSTMP : TIMESTAMP
    STR : VARCHAR2
    BOOL : NUMBER
    COLL : SYS.ODCINUMBERLIST
    STRUCT : SYS.ODCIOBJECT
    CLOB : CLOB
  }

  {
    byte : 1
    short : 1
    int : 1
    longint : 1
    float : *BINARY_VALUE*
    double : 1.2
    numeric : 1.56
    date : 31.03.2055 00:00:00
    timestamp : *JAVA_OBJ_REF*
        timestamp is datetime? - false
        timestamp is string? - true
    string : text
    boolean : 1
        boolean is int? - true
    collection = [1, 2, 3]
    struct = {field#1 : "duck", field#2 : "goose"}
    clob = loooong text
  }

  {
    number : 2
    string : abcx
    date : 12.03.2000
    collection : ['a', 'b', 'c', 'd']
    cursor : {
      row#1: "DT" = 02.03.2015
      row#2: "DT" = 03.03.2015
      row#3: "DT" = 04.03.2015
      row#4: "DT" = 05.03.2015
      row#5: "DT" = 06.03.2015
    }
  }

  {
    "N" : [1, 2, 3, 4, 5]
    "LABEL" : [row_1, row_2, row_3, row_4, row_5]
  }

--%end java_binds_res_ora10

--%begin java_hlp_methods1
  ${static("java.lang.Math").sqrt(2)?c}

  ${template_line()}

--%end java_hlp_methods1


--%begin java_hlp_methods1_res
  1.4142135623730951

  3

--%end java_hlp_methods1_res


--%begin java_hlp_methods2_beg
  <#assign void = shared_hash.put("xxx", 123)>

--%end java_hlp_methods2_beg


--%begin java_hlp_methods2_end
  ${shared_hash.get("xxx")}

--%end java_hlp_methods2_end


--%begin java_hlp_methods2_res
  123

--%end java_hlp_methods2_res


--%begin java_hlp_methods3
  template_name = "${template_name()}"
--%end java_hlp_methods3

--%begin std
<#import "/ftldb/std.ftl" as std>

<#assign a = std.least(5, 3, 7, 9)>
<#assign b = std.greatest(5, 3, 17, 9)>
<#assign c = std.ltrim('     x  ')>
<#assign d = std.rtrim('     x  ')>
${a?c} ${b?c} "${c}" "${d}"

<#assign a = std.to_list(["col1", "col2", "col3"], 't.# = v.#', ' and ', '#')>
"${a}"

<#global TAB_SIZE = 3/>
<@std.indent ltab=1>
line1
  line2
    line3
      line4
</@std.indent>
<#global TAB_SIZE = 2/>

<@std.indent rshift=2>
line1
  line2
    line3
      line4
</@std.indent>

<@std.format_list
  trailing_delim = false
  max_len = 20
>
  column1,
  column2,
  column3,
  column4,
  column5
</@std.format_list>

<@std.format_list
  trailing_delim = false
  max_len = 20
>
  column1,
  column2,
  column3,
  column4,
  column5
</@std.format_list>

<@std.format_list
  delim = '; '
  trailing_delim = true
  max_len = 20
>
  column1,
  column2,
  column3,
  column4,
  column5
</@std.format_list>

<@std.format_list
  max_len = 0
>
  column1,column2, column3,column4, column5
</@std.format_list>

<@std.format_list
  split_ptrn = '\\s*;\\s*'
  max_len = 20
>
  column1;column2; column3;column4; column5
</@std.format_list>

<@std.format_list
  max_len = 30
  lshift = 2
>
            column1,column2, column3 ,column4 , column5
</@std.format_list>

<@std.format_list
  max_len = 30
  keep_indent = false
>
            column1,column2, column3 ,column4 , column5
</@std.format_list>


--%end std

--%begin std_res
3 17 "x  " "     x"

"t.col1 = v.col1 and t.col2 = v.col2 and t.col3 = v.col3"

line1
line2
 line3
   line4

  line1
    line2
      line3
        line4

  column1, column2,
  column3, column4,
  column5

  column1, column2,
  column3, column4,
  column5

  column1; column2;
  column3; column4;
  column5;

  column1,
  column2,
  column3,
  column4,
  column5

  column1, column2,
  column3, column4,
  column5

          column1, column2,
          column3, column4,
          column5

column1, column2, column3,
column4, column5


--%end std_res


--%begin orasql
  <#import "/ftldb/std.ftl" as std>
  <#import "/ftldb/orasql.ftl" as sql>

  <#assign res = sql.scalar("add_months", ['20-01-2000'?date['dd-MM-yyyy'], 1])>
  ${res?string["dd.MM.yyyy"]}

  <#assign res = sql.eval("DATE", "add_months", ['20-01-2000'?date['dd-MM-yyyy'], 1])>
  ${res?string["dd.MM.yyyy"]}

  <#assign res = sql.eval("NUMERIC", "utl_raw.big_endian")>
  ${res}

  <#assign res = sql.eval("BOOLEAN", "dbms_db_version.ver_le_9")>
  ${res?c}

  <#assign res = sql.collect("sys.odcinumberlist", [1,3,5,7])/>
  ${std.to_list(res)}

  <#assign res = sql.fetch("ut_ftldb_api.ut_process#orasql#fetch", [3])/>
  ${std.to_list(res.transpose()[0])}

--%end orasql


--%begin orasql_res
  20.02.2000

  20.02.2000

  1

  false

  1, 3, 5, 7

  1, 2, 3

--%end orasql_res


$end

end ut_ftldb_api$process;
/
