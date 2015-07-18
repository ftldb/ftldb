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
  <#assign conn = default_connection()>
  <#assign ora_ver = conn.exec("begin :1 := dbms_db_version.version; end;", {}, {"1" : "NUMERIC"})["1"]>
  <#assign udt = conn.query("select sys.odcinumberlist(1,2,3) from dual").seq_rows[0][0]>

  <#assign
    res = conn.query(
      "select :1 byte, :2 shrt, :3 int, :4 lngint, :5 flt, :6 dbl, :7 bigdec, " +
      " :8 + 1/7 dt, :9 tmstmp, :10 str, :11 bool, :12 udt from dual",
      [
        1?byte, 1?short, 1?int, 1?long, 1.2?float, 1.2?double, 1.56,
        "31.03.2055"?date["dd.MM.yyyy"],
        "31.03.2012 17:23:39.544"?datetime["dd.MM.yyyy HH:mm:ss.SSS"],
        "text", true, udt
      ]
    )
  />

  <#list res.col_meta_seq as currCol>
  ${currCol.name} ${currCol.typeName}
  </#list>

  <#assign r = res.hash_rows[0]>

  byte = ${r.BYTE?c}
  short = ${res.hash_rows[0].SHRT?c}
  int = ${res.hash_rows[0].INT?c}
  longint = ${res.hash_rows[0].LNGINT?c}
  float = <#if (ora_ver < 11)>*BINARY_VALUE*<#else/>${res.hash_rows[0].FLT?c}</#if>
  double = ${res.hash_rows[0].DBL?c}
  numeric = ${res.hash_rows[0].BIGDEC?c}
  date = ${res.hash_rows[0].DT?string["dd.MM.yyyy HH:mm:ss"]}
  timestamp returned as datetime? = ${res.hash_rows[0].TMSTMP?is_unknown_date_like?c}
  timestamp returned as string? = ${res.hash_rows[0].TMSTMP?is_string?c}
  timestamp = <#if (ora_ver < 11)>*JAVA_OBJ_REF*<#else/>${res.hash_rows[0].TMSTMP}</#if>
  string = ${res.hash_rows[0].STR}
  boolean returned as int? = ${res.hash_rows[0].BOOL?is_number?c}
  boolean = ${res.hash_rows[0].BOOL?c}
  udt = [<#list res.hash_rows[0].UDT.getArray() as i>${i}<#sep>, </#list>]


  <#assign udt2 = conn.query("select sys.odcivarchar2list('a', 'b', 'c') from dual").seq_rows[0][0]>

  <#assign
    res =
    conn.exec(
      "declare\n" +
      "  v1 number := :1;\n" +
      "  v2 varchar2(200) := :2;\n" +
      "  v3 date := :3;\n" +
      "  v4 sys.odcivarchar2list := :4;\n" +
      "begin\n" +
      "  :5 := v1 + 1;\n" +
      "  :6 := v2 || 'x';\n" +
      "  :7 := add_months(v3, 1);\n" +
      "  v4.extend(); v4(v4.last()) := 'd';\n" +
      "  :8 := v4;\n" +
      "end;",
      {"1" : 1, "2" : "abc", "3" : "12.02.2000"?date["dd.MM.yyyy"], "4" : udt2},
      {"5" : "NUMERIC", "6" : "VARCHAR", "7" : "DATE", "8" : "ARRAY:SYS.ODCIVARCHAR2LIST"}
    )
  />

  number = ${res["5"]}
  string = ${res["6"]}
  date = ${res["7"]?string["dd.MM.yyyy"]}
  udt2 = [<#list res["8"].getArray() as i>'${i}'<#sep>, </#list>]

--%end java_binds


--%begin java_binds_res

  BYTE NUMBER
  SHRT NUMBER
  INT NUMBER
  LNGINT NUMBER
  FLT NUMBER
  DBL NUMBER
  BIGDEC NUMBER
  DT DATE
  TMSTMP TIMESTAMP
  STR VARCHAR2
  BOOL NUMBER
  UDT SYS.ODCINUMBERLIST


  byte = 1
  short = 1
  int = 1
  longint = 1
  float = 1.2
  double = 1.2
  numeric = 1.56
  date = 31.03.2055 03:25:43
  timestamp returned as datetime? = false
  timestamp returned as string? = true
  timestamp = 2012-03-31 17:23:39.544
  string = text
  boolean returned as int? = true
  boolean = 1
  udt = [1, 2, 3]



  number = 2
  string = abcx
  date = 12.03.2000
  udt2 = ['a', 'b', 'c', 'd']

--%end java_binds_res


--%begin java_binds_res_ora10

  BYTE NUMBER
  SHRT NUMBER
  INT NUMBER
  LNGINT NUMBER
  FLT NUMBER
  DBL NUMBER
  BIGDEC NUMBER
  DT DATE
  TMSTMP TIMESTAMP
  STR VARCHAR2
  BOOL NUMBER
  UDT SYS.ODCINUMBERLIST


  byte = 1
  short = 1
  int = 1
  longint = 1
  float = *BINARY_VALUE*
  double = 1.2
  numeric = 1.56
  date = 31.03.2055 00:00:00
  timestamp returned as datetime? = false
  timestamp returned as string? = true
  timestamp = *JAVA_OBJ_REF*
  string = text
  boolean returned as int? = true
  boolean = 1
  udt = [1, 2, 3]



  number = 2
  string = abcx
  date = 12.03.2000
  udt2 = ['a', 'b', 'c', 'd']

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

--%begin standard
<#import "ftldb_standard_ftl" as std>

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


--%end standard

--%begin standard_res
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


--%end standard_res


--%begin sql
  <#import "ftldb_standard_ftl" as std>
  <#import "ftldb_sql_ftl" as sql>

  <#assign res = sql.select("add_months", "20-01-2000"?date["dd-MM-yyyy"], 1)>
  ${res?string["dd.MM.yyyy"]}

  <#assign res = sql.eval("DATE", "add_months", "20-01-2000"?date["dd-MM-yyyy"], 1)>
  ${res?string["dd.MM.yyyy"]}

  <#assign res = sql.eval("NUMERIC", "utl_raw.big_endian")>
  ${res}

  <#assign res = sql.eval("BOOLEAN", "dbms_db_version.ver_le_9")>
  ${res?c}

  <#assign res =
    default_connection()
    .query("select nullif(rownum, 2) c1, rownum*2 c2 from dual connect by level <= 4")
  />

  <#assign rs1 = res.seq_rows>
  <#assign rs2 = res.hash_rows>

  ${std.to_list(sql.get_column(rs1, 0))}
  ${std.to_list(sql.get_column(rs2, 'C2'))}

  <#assign res = sql.collect([1,3,5,7], 'sys.odcinumberlist')/>
  ${std.to_list(res.getArray())}

  <#assign res = sql.fetch("ut_ftldb_api.ut_process#sql#fetch", "3")/>
  ${std.to_list(res.col_seq[0])}

--%end sql


--%begin sql_res
  20.02.2000

  20.02.2000

  1

  false


  1, 3, 4
  2, 4, 6, 8

  1, 3, 5, 7

  1, 2, 3

--%end sql_res


$end

end ut_ftldb_api$process;
/
