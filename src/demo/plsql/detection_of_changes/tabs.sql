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

--drop table demo_goods


create table demo_goods(
  id number(14) not null primary key,
  code varchar2(30) not null check(code = lower(trim(code))),
  category varchar2(30) check(category = lower(trim(category))),
  name varchar2(200) not null,
  --
  unique(code, category)
)
/

create table demo_warehouses(
  id number(14) not null primary key,
  code varchar2(30) not null check(code = lower(trim(code))),
  city varchar2(90) not null check(city = lower(trim(city))),
  name varchar2(200) not null,
  --
  unique(code, city)
)
/


create table demo_goods_in_whs(
  whs_id number(14) not null references demo_warehouses(id),
  goods_id number(14) not null references demo_goods(id),
  primary key(whs_id, goods_id),
  quantity number(9) not null check(quantity > 0)
)
/

create sequence demo_change_seq
start with 1
cache 8192
order
/
