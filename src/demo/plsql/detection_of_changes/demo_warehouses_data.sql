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

merge into demo_warehouses d
using(
  select 1 id, 'main' code, 'hurghada' city, 'main warehouse' name from dual union all
  select 2 id, 'dc' code, 'sharm' city, 'Sharm dive center' name from dual union all
  select 3 id, 'naamashop' code, 'sharm' city, 'Naama center shop' name from dual union all
  select 4 id, 'rusalka' code, 'hurghada' city, 'Rusalka safari boat' name from dual union all
  select 5 id, 'tempboat' code, 'sharm' city, 'daily boat Travco' name from dual union all
  select 6 id, 'tempboat' code, 'hurghada' city, 'daily boat Hurgada marina' name from dual union all
  /*
  select 5 id, 'temporary boat #1' name from dual union all
  */
  select 99 id, '' code, '' city, '' name from dual where 1=2
) s
on ( d.id = s.id )
when not matched then insert(id, code, city, name) values(s.id, s.code, s.city, s.name)
/

begin
  dbms_stats.gather_table_stats(user, 'demo_warehouses');
end;
/
