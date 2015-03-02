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

create or replace package generator as

procedure gen_orders_plsql;

function get_partitions return sys_refcursor;
function gen_orders_ftldb return ftldb_script_ot;

end;
/
create or replace package body generator as


-- data for partitioning clause generation
cursor cur_partitions is
  select
    t.region name, 
    listagg(t.shop_id, ', ') 
      within group (order by t.shop_id) vals 
  from shops t 
  group by t.region
  order by t.region;


procedure gen_orders_plsql
is
  l_scr clob;  
begin
  l_scr :=   
    'create table orders (' || chr(10) ||
    '  order_id integer not null primary key,' || chr(10) ||
    '  customer_id integer not null,' || chr(10) ||
    '  shop_id integer not null,' || chr(10) ||
    '  order_date date not null,' || chr(10) ||
    '  status varchar2(10) not null' || chr(10) ||
    ')' || chr(10) ||
    'partition by list(shop_id) (';

  for r in cur_partitions
  loop
    l_scr := l_scr ||
      case when cur_partitions%rowcount > 1 then ',' end || chr(10) ||
      '  partition ' || r.name || ' values (' || r.vals || ')';
  end loop;
   
  l_scr := l_scr || chr(10) || ')';

  dbms_output.put_line(l_scr);
  dbms_output.put_line('/');
  execute immediate l_scr;
  
  l_scr := 'comment on table orders is ''Orders partitioned by region.''';

  dbms_output.put_line(l_scr);
  dbms_output.put_line('/');
  execute immediate l_scr;
  
end;


function get_partitions return sys_refcursor
is
  l_rc sys_refcursor;
begin
  -- data for partitioning clause generation
  open l_rc for
    select
      t.region name, 
      listagg(t.shop_id, ', ') 
        within group (order by t.shop_id) vals 
    from shops t 
    group by t.region
    order by t.region;
    
  return l_rc;
end; 


$if null $then
--%begin orders_ftl

<#import "ftldb_sql_ftl" as sql/>

<#assign partitions = sql.fetch('generator.get_partitions')/>  
                                                                                                                                            
create table orders (
  order_id integer not null primary key,
  customer_id integer not null,
  shop_id integer not null,
  order_date date not null,
  status varchar2(10) not null
)
partition by list(shop_id) (
<#list partitions.hash_rows as p>
  partition ${p.NAME} values (${p.VALS})<#if p_has_next>,</#if>
</#list>  
)
</>

comment on table orders is 'Orders partitioned by region.'
</>

--%end orders_ftl
$end


function gen_orders_ftldb return ftldb_script_ot
is
begin
  return ftldb_api.process($$plsql_unit || '%orders_ftl');
end;


end;
/
