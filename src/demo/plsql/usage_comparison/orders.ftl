<#--

    Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

-->
<#assign
  conn = new_connection(
    "jdbc:oracle:thin:@//" + template_args[0],
    template_args[1], template_args[2]
  )
/>

<#assign
  partitions = conn.query(
    "select " +
      "t.region name, " +
      "listagg(t.shop_id, ', ') within group (order by t.shop_id) vals " +
    "from shops t " +
    "group by t.region " +
    "order by t.region"
  )
/>

create table orders (
  order_id integer not null primary key,
  customer_id integer not null,
  shop_id integer not null,
  order_date date not null,
  status varchar2(10) not null
)
partition by list(shop_id) (
<#list partitions as p>
  partition ${p.NAME} values (${p.VALS})<#sep>,</#sep>
</#list>
)
/

comment on table orders is 'Orders partitioned by region.'
/

<#assign void = conn.close()/>
