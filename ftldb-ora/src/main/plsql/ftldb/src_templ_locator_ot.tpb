--
-- Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy
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

create or replace type body src_templ_locator_ot as


static function new(
  in_templ_name in varchar2
) return src_templ_locator_ot
is
  l_locator src_templ_locator_ot :=
    src_templ_locator_ot(in_templ_name, null, null, null, null, null);
begin
  if in_templ_name like '@%' then
    source_util.resolve_long_name(
      substr(in_templ_name, 2),
      l_locator.owner, l_locator.obj_name, l_locator.dblink,
      l_locator.type
    );
  else
    source_util.resolve_src_name(
      in_templ_name,
      l_locator.owner, l_locator.obj_name, l_locator.sec_name, l_locator.dblink,
      l_locator.type
    );
  end if;
  return l_locator;
exception
  when source_util.e_name_not_resolved then
    return null;
end new;


overriding member function get_templ_body return clob
is
begin
  return
    case
      when self.sec_name is not null then
        source_util.extract_named_section(
          self.owner, self.obj_name, self.dblink, self.type, self.sec_name
        )
      when self.type in ('JAVA RESOURCE') then
        source_util.get_obj_source(
          self.owner, self.obj_name, self.dblink, self.type
        )
      else
        source_util.extract_noncompiled_section(
          self.owner, self.obj_name, self.dblink, self.type
        )
    end;
end get_templ_body;


overriding member function get_last_modified return integer
is
begin
  return
    to_number(to_char(
      source_util.get_obj_timestamp(
        self.owner, self.obj_name, self.dblink, self.type
      ),
      'yyyymmddhh24miss'
    ));
end get_last_modified;


end;
/
