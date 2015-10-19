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

create or replace view demo_other1_src(
  code primary key rely disable,
  name
) as
select 1 code, 'some...' name from dual
/

comment on table demo_other1_src is 'Another data source #1.';

create or replace view demo_other2_src(
  key_part1, key_part2, key_part3, key_part4, key_part5,
  --
  primary key(
    key_part1, key_part2, key_part3, key_part4, key_part5
  ) rely disable,
  --
  col1, col2, col3, col4, col5, col6, col7
) as
select
  1 key_part1,
  2 key_part2,
  date'2015-01-10' key_part3,
  cast(timestamp'2015-01-10 15:34:41.23' as timestamp(9)) key_part4,
  5 key_part5,
  --
  sysdate col1,
  'a' col2,
  utl_raw.cast_to_raw('b') col3,
  cast('v' as varchar2(30)) col4,
  'g' col5,
  'd' col6,
  123.45 col7
from dual
/

comment on table demo_other2_src is 'Another data source #2.';
