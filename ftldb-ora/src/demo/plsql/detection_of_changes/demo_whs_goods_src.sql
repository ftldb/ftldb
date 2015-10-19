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

-- The contract view of external data.
create or replace view demo_whs_goods_src(
  whs_code, whs_city, whs_alias,
  goods_code, goods_category,
  quantity,
  unique(whs_code, whs_city, goods_code, goods_category) rely disable
) as
select
  s.whs_code, s.whs_city,
  s.whs_alias, -- expression returning not null value; must be checked
  s.goods_code, s.goods_category,
  s.quantity -- may become nullable in future
from demo_whs_goods s
/

-- We use annotations to enforce constraints that cannot be realized as native.
-- They are used by the generator.
comment on table demo_whs_goods_src is 'Demo source view.';
comment on column demo_whs_goods_src.whs_alias is
  'Alias of warehouse. @mandatory';
comment on column demo_whs_goods_src.goods_category is
  'Optional category of goods.';
comment on column demo_whs_goods_src.quantity is
  'Quantity of goods. @nullable';
