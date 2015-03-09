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

-- Suppose this is an external view that is exposed for our ETL.
create or replace view demo_whs_goods(
  whs_code, whs_city, whs_alias,
  goods_code, goods_category,
  quantity,
  unique(whs_code, whs_city, goods_code, goods_category) rely disable
) as
select
  w.code whs_code, w.city whs_city,
  w.code || '-' || w.city whs_alias, -- expression returning not null values
  g.code goods_code, g.category goods_category,
  gw.quantity
from demo_goods_in_whs gw
  join demo_warehouses w on w.id = gw.whs_id
  join demo_goods g on g.id = gw.goods_id
/
