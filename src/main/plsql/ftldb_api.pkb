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

create or replace package body ftldb_api as


/**
 * Returns the owner of this package.
 */
function get_this_schema return varchar2
is
  l_owner varchar2(30);
  l_name varchar2(30);
  l_line number;
  l_type varchar2(30);
begin
  owa_util.who_called_me(l_owner, l_name, l_line, l_type);
  return l_owner;
end get_this_schema;


function default_template_loader(in_templ_name in varchar2) return clob
is
begin
  return
    case
      when in_templ_name like '%\%%' escape '\' then
        source_util.extract_named_section(
          regexp_replace(in_templ_name, '%[^%@]+'),
          regexp_replace(in_templ_name, '^([^%]+%?)([^%@]*)(@[^@]+)?$', '\2')
        )
      else
        source_util.extract_noncompiled_section(in_templ_name)
    end;
exception
  when
    source_util.e_name_not_resolved or source_util.e_source_not_found or
    source_util.e_section_not_found
  then
    return null;
end default_template_loader;


procedure init(in_templ_loader in varchar2 := null)
is
begin
  ftldb_wrapper.new_configuration();
  ftldb_wrapper.set_db_template_loader(
    '{? = call ' ||
      coalesce(
        in_templ_loader,
        get_this_schema() || '.' || $$plsql_unit || '.default_template_loader'
      ) ||
      '(?)}'
  );
end init;


function process_to_clob(
  in_templ_name in varchar2,
  in_templ_args in varchar2_nt := varchar2_nt()
) return clob
is
begin
  ftldb_wrapper.set_arguments(in_templ_args);
  return ftldb_wrapper.process(in_templ_name);
end process_to_clob;


function process_body_to_clob(
  in_templ_body in clob,
  in_templ_args in varchar2_nt := varchar2_nt()
) return clob
is
begin
  ftldb_wrapper.set_arguments(in_templ_args);
  return ftldb_wrapper.process_body(in_templ_body);
end process_body_to_clob;


function process(
  in_templ_name in varchar2,
  in_templ_args in varchar2_nt := varchar2_nt(),
  in_stmt_delim in varchar2 := '</>'
) return script_ot
is
begin
  return
    script_ot(
      process_to_clob(in_templ_name, in_templ_args),
      in_stmt_delim
    );
end process;


function process_body(
  in_templ_body in clob,
  in_templ_args in varchar2_nt := varchar2_nt(),
  in_stmt_delim varchar2 := '</>'
) return script_ot
is
begin
  return
    script_ot(
      process_body_to_clob(in_templ_body, in_templ_args),
      in_stmt_delim
    );
end process_body;


function get_version return varchar2
is
begin
  return ftldb_wrapper.get_version();
end get_version;


function get_version_number return integer
is
begin
  return ftldb_wrapper.get_version_number();
end get_version_number;


begin
  init();
exception
  when others then
    dbms_session.modify_package_state(dbms_session.reinitialize);
    raise_application_error(-20000, 'FTLDB initialization failed', true);
end ftldb_api;
/
