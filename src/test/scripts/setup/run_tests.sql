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

prompt Run UT_CLOB_UTIL tests.
begin
  ut_clob_util.ut_create_temporary();
  ut_clob_util.ut_put();
  ut_clob_util.ut_put_line();
  ut_clob_util.ut_append;
  ut_clob_util.ut_join();
  ut_clob_util.ut_split_into_lines();
  ut_clob_util.ut_split_into_pieces();
  ut_clob_util.ut_show();
  ut_clob_util.ut_exec();
end;
/

prompt Run UT_SOURCE_UTIL tests.
begin
  ut_source_util.ut_long2clob();

  ut_source_util.ut_resolve_ora_name#own_object();
  ut_source_util.ut_resolve_ora_name#others_obj();
  ut_source_util.ut_resolve_ora_name#dblink_obj();
  ut_source_util.ut_resolve_ora_name#dbl_oth_ob();

  ut_source_util.ut_get_obj_source#view();
  ut_source_util.ut_get_obj_source#func();

  ut_source_util.ut_extr_sect_from_clob#default();
  ut_source_util.ut_extr_sect_from_clob#w_bound();
  ut_source_util.ut_extr_sect_from_clob#lazy();
  ut_source_util.ut_extr_sect_from_clob#greedy();

  ut_source_util.ut_extr_sect_from_obj#w_bound();
  ut_source_util.ut_extr_noncmp_sect();
  ut_source_util.ut_extr_named_sect();

  ut_source_util.ut_repl_sect_in_clob#default();
  ut_source_util.ut_repl_sect_in_clob#w_bound();
  ut_source_util.ut_repl_sect_in_clob#lazy();
  ut_source_util.ut_repl_sect_in_clob#greedy();

  ut_source_util.ut_repl_nm_sect_in_clob#lazy();
  ut_source_util.ut_repl_nm_sect_in_clob#greedy();
end;
/

prompt Run UT_SCRIPT_OT tests.
begin
  ut_script_ot.ut_constructor#clob_nt();
  ut_script_ot.ut_constructor#clob();

  ut_script_ot.ut_to_clob();

  ut_script_ot.ut_append#clob();
  ut_script_ot.ut_append#script();

  ut_script_ot.ut_show#statement();
  ut_script_ot.ut_show#script();

  ut_script_ot.ut_exec#statement();
  ut_script_ot.ut_exec#script();
end;
/

prompt Run UT_FTLDB_API tests.
begin
  ut_ftldb_api.ut_dflt_templ_loader#proc;
  ut_ftldb_api.ut_dflt_templ_loader#sect;

  ut_ftldb_api.ut_process#args;
  ut_ftldb_api.ut_process#include_args;
  ut_ftldb_api.ut_process#java_binds;
  ut_ftldb_api.ut_process#java_hlp_methods1;
  ut_ftldb_api.ut_process#java_hlp_methods2;
  ut_ftldb_api.ut_process#standard;
  ut_ftldb_api.ut_process#sql;
end;
/
