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

declare
  l_scr ftldb_script_ot := ftldb_script_ot();
begin

  for r in (
    select 'drop ' || lower(lst.tp) || ' ' || lower(lst.nm) cmd
    from user_objects o
      join(
        select 1 ord, 'PACKAGE' tp, 'DEMO_DTOCH_GEN' nm from dual union all
        select 2 ord, 'VIEW' tp, 'DEMO_WHS_GOODS_SRC' nm from dual union all
        select 3 ord, 'VIEW' tp, 'DEMO_OTHER1_SRC' nm from dual union all
        select 4 ord, 'VIEW' tp, 'DEMO_OTHER2_SRC' nm from dual union all
        select 5 ord, 'VIEW' tp, 'DEMO_WHS_GOODS' nm from dual union all
        select 6 ord, 'TYPE' tp, 'DEMO_DTOCH_GEN_PR_NT' nm from dual union all
        select 7 ord, 'TYPE' tp, 'DEMO_DTOCH_GEN_PR_OT' nm from dual union all
        select 8 ord, 'TABLE' tp, 'DEMO_GOODS_IN_WHS' nm from dual union all
        select 9 ord, 'TABLE' tp, 'DEMO_WAREHOUSES' nm from dual union all
        select 10 ord, 'TABLE' tp, 'DEMO_GOODS' nm from dual union all
        select 11 ord, 'SEQUENCE' tp, 'DEMO_CHANGE_SEQ' nm from dual union all
        select 99 ord, '' tp, '' nm from dual where 1=2
      ) lst
      on o.object_type = lst.tp and o.object_name = lst.nm
    order by lst.ord
  ) loop
    l_scr.append(r.cmd);
  end loop;

  l_scr.exec(true);

end;
/
