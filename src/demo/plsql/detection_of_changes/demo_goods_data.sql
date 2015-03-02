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


merge into demo_goods d
using(
  select 1 id, 'sleepstream_xl' code, '' category, 'OMS Sleep Stream XL' name from dual union all
  select 2 id, 'regulator_aqualung_legend' code, '' category, 'Regulator Aqualung Legend' name from dual union all
  select 3 id, 'tank_12' code, 'alu_air' category, 'Tank aluminum air 11.3L' name from dual union all
  select 4 id, 'tank_12' code, 'alu_oxy' category, 'Tank aluminum oxygen 11.3L' name from dual union all
  select 5 id, 'tank_12' code, 'stl_air' category, 'Tank steel air 12L' name from dual union all
  select 6 id, 'tank_12' code, 'stl_pxy' category, 'Tank steel oxygen 12L' name from dual union all
  select 7 id, 'tank_12' code, '' category, 'Unknown Tank (needs to be categorized)' name from dual union all
  select 99 id, '' code, '' category, '' name from dual where 1=2
) s
on ( d.id = s.id )
when not matched then insert(id, code, category, name) values(s.id, s.code, s.category, s.name)
/

begin
  dbms_stats.gather_table_stats(user, 'demo_goods');
end;
/
