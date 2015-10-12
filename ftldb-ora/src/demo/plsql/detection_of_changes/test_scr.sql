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

function is_same return boolean
is
  l_cnt number(5);
begin
  select count(1) cnt
  into l_cnt
  from
    (
    (
    select whs_code, whs_city, whs_alias, goods_code, goods_category, quantity
    from demo_whs_goods
    minus
    select whs_code, whs_city, whs_alias, goods_code, goods_category, quantity
    from demo_whs_goods_snap s
    where s.is_alive = 'Y'
    )
    union all
    (
    select whs_code, whs_city, whs_alias, goods_code, goods_category, quantity
    from demo_whs_goods_snap s
    where s.is_alive = 'Y'
    minus
    select whs_code, whs_city, whs_alias, goods_code, goods_category, quantity
    from demo_whs_goods
    )
    ) z
  ;
  return l_cnt = 0;
end;

procedure ensure_same
is
begin
  if not is_same then
    raise_application_error(
      -20000, 'The source and the destination are not the same.'
    );
  end if;
end;

procedure ensure_not_same
is
begin
  if is_same then
    raise_application_error(
      -20000, 'The source and the destination are the same.'
    );
  end if;
end;

begin

  delete demo_goods_in_whs;

  insert into demo_goods_in_whs(whs_id, goods_id, quantity)
  select w.id whs_id, g.id goods_id, mod(ora_hash(w.id || '.' || g.id), 5) + 1
  from demo_goods g
    cross join demo_warehouses w
  where mod(ora_hash(g.name || '.' || w.name), 7) = 1;

  commit;

  demo_dtoch.process();
  commit;
  ensure_same();

  delete demo_goods_in_whs
  where mod(ora_hash(whs_id || '.' || goods_id || '.' || quantity), 3) = 2;

  ensure_not_same();

  demo_dtoch.process();
  commit;
  ensure_same();

  merge into demo_goods_in_whs d
  using(
    select w.id whs_id, g.id goods_id, mod(ora_hash(w.id || '.' || g.id), 5) + 1
    from demo_goods g
      cross join demo_warehouses w
    where mod(ora_hash(g.name || '.' || w.name), 3) = 2
  ) s
  on ( d.whs_id = s.whs_id and d.goods_id = s.goods_id )
  when not matched then
    insert(whs_id, goods_id, quantity) values(
      s.whs_id, s.goods_id, mod(ora_hash(s.whs_id || '.' || s.goods_id), 5) + 1
    );
  commit;

  ensure_not_same();

  demo_dtoch.process();
  commit;
  ensure_same();

  delete demo_goods_in_whs;
  commit;

  ensure_not_same();

  demo_dtoch.process();
  commit;
  ensure_same();

  insert into demo_goods_in_whs(whs_id, goods_id, quantity)
  select w.id whs_id, g.id goods_id, mod(ora_hash(w.id || '.' || g.id), 5) + 1
  from demo_goods g
    cross join demo_warehouses w
  where mod(ora_hash(g.name || '.' || w.name), 7) = 1;

  commit;
  ensure_not_same();

  demo_dtoch.process();
  commit;
  ensure_same();

  update demo_goods_in_whs set quantity = 17;
  commit;
  ensure_not_same();

  demo_dtoch.process();
  commit;
  ensure_same();


end;
/
