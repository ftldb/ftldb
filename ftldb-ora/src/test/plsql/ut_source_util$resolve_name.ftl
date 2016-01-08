<#--

    Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy

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
<#macro create_dblink name user pswd conn>
create or replace procedure create_dblink_${name}
as
begin
  execute immediate '
    create database link ${name}
    connect to ${user}
    identified by ${pswd}
    using ''${conn}''
  ';
end;
/
exec create_dblink_${name};
drop procedure create_dblink_${name};

</#macro>

-- Extra objects in ${demo_schema} --
<@set_current demo_schema/>
<@create_dblink demo_schema+"$ext1" demo_schema+"_ext1" "&&demo_pswd." instance_tns_name/>

-- Extra objects in ${demo_schema}_EXT1 --
<@set_current demo_schema+"_ext1"/>
create or replace function testfunc return number as
begin return null; end;
/
grant execute on testfunc to ${demo_schema};

-- Extra objects in ${demo_schema}_EXT2 --
<@set_current demo_schema+"_ext2"/>
create or replace view testview as
select 1 x
from dual
/
grant select on testview to ${demo_schema}_ext1;

-- Return to ${demo_schema} --
<@set_current demo_schema/>
