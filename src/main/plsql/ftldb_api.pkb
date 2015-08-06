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


procedure default_template_resolver(
  in_templ_name in varchar2,
  out_owner out varchar2,
  out_name out varchar2,
  out_sec_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
)
is
begin
  source_util.resolve_templ_name(
    in_templ_name, out_owner, out_name, out_sec_name, out_dblink, out_type
  );
exception
  -- freemarker.cache.TemplateLoader needs null-object in order to process
  -- the "template not found" error correctly
  when source_util.e_name_not_resolved then null;
end default_template_resolver;


procedure default_template_loader(
  in_owner in varchar2,
  in_name in varchar2,
  in_sec_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2,
  out_body out clob
)
is
begin
  out_body :=
    case
      when in_sec_name is null then
        source_util.extract_noncompiled_section(
          in_owner, in_name, in_dblink, in_type
        )
      else
        source_util.extract_named_section(
          in_owner, in_name, in_dblink, in_type, in_sec_name
        )
    end;
end default_template_loader;


/**
 * Converts Oracle timestamp to milliseconds since Unix Epoch.
 */
function timestamp2millis(in_timestamp timestamp) return integer
is
  c_interval constant interval day(9) to second(3) :=
    sys_extract_utc(in_timestamp) - timestamp '1970-01-01 00:00:00';
begin
  return 1000 * (
    extract(day from c_interval) * 86400 +
    extract(hour from c_interval) * 3600 +
    extract(minute from c_interval) * 60 +
    extract(second from c_interval)
  );
end timestamp2millis;


procedure default_template_checker(
  in_owner in varchar2,
  in_name in varchar2,
  in_sec_name in varchar2, --not used
  in_dblink in varchar2,
  in_type in varchar2,
  out_millis out integer
)
is
begin
  out_millis := timestamp2millis(
    source_util.get_obj_timestamp(in_owner, in_name, in_dblink, in_type)
  );
end default_template_checker;


function default_config_xml return xmltype
is
  c_pkg_name constant varchar2(70) :=
    '"' || get_this_schema() || '"."' || $$plsql_unit || '"';

  c_resolver_call constant varchar2(4000) :=
    '{call ' || c_pkg_name || '.default_template_resolver(?, ?, ?, ?, ?, ?)}';
  c_loader_call constant varchar2(4000) :=
    '{call ' || c_pkg_name || '.default_template_loader(?, ?, ?, ?, ?, ?)}';
  c_checker_call constant varchar2(4000) :=
    '{call ' || c_pkg_name || '.default_template_checker(?, ?, ?, ?, ?, ?)}';

  c_config constant varchar2(32767) :=
    '<?xml version="1.0" encoding="UTF-8"?>
    <java version="1.4.0" class="java.beans.XMLDecoder">
      <object class="ftldb.DefaultConfiguration">
        <void property="templateLoader">
          <object class="ftldb.oracle.DatabaseTemplateLoader">
            <string>' || utl_i18n.escape_reference(c_resolver_call) || '</string>
            <string>' || utl_i18n.escape_reference(c_loader_call) || '</string>
            <string>' || utl_i18n.escape_reference(c_checker_call) || '</string>
          </object>
        </void>
        <void property="cacheStorage">
          <object class="freemarker.cache.MruCacheStorage">
            <int>20</int>
            <int>200</int>
          </object>
        </void>
      </object>
    </java>';
begin
  return xmltype(c_config);
end default_config_xml;


function get_config_func_name return varchar2
is
  l_owner varchar2(30);
  l_name varchar2(30);
  l_dblink varchar2(128);
  l_type varchar2(30);
  c_default_config_func_name varchar2(70) :=
    '"' || get_this_schema() || '"."' || $$plsql_unit || '"' ||
    '.default_config_xml';
begin
  source_util.resolve_ora_name(
    'ftldb_config_xml', l_owner, l_name, l_dblink, l_type
  );
  if l_type != 'FUNCTION' then
    return c_default_config_func_name;
  end if;
  return source_util.get_full_name(l_owner, l_name, l_dblink);
exception
  when source_util.e_name_not_resolved then
    return c_default_config_func_name;
end get_config_func_name;


procedure init(in_config_xml in xmltype)
is
begin
  ftldb_wrapper.set_configuration(in_config_xml.getclobval());
end init;


procedure init(in_config_func_name in varchar2)
is
  l_config_xml xmltype;
begin
  execute immediate
    'call ' || dbms_assert.sql_object_name(in_config_func_name) || '() into :1'
  using out l_config_xml;

  init(l_config_xml);
end init;


procedure init
is
begin
  init(get_config_func_name());
end init;


function process_to_clob(
  in_templ_name in varchar2,
  in_templ_args in varchar2_nt := varchar2_nt()
) return clob
is
  l_result clob := clob_util.create_temporary();
begin
  ftldb_wrapper.set_arguments(in_templ_args);
  ftldb_wrapper.process(in_templ_name, l_result);
  return l_result;
end process_to_clob;


function process_body_to_clob(
  in_templ_body in clob,
  in_templ_args in varchar2_nt := varchar2_nt()
) return clob
is
  l_result clob := clob_util.create_temporary();
begin
  ftldb_wrapper.set_arguments(in_templ_args);
  ftldb_wrapper.process_body(in_templ_body, l_result);
  return l_result;
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


function get_freemarker_version return varchar2
is
begin
  return ftldb_wrapper.get_freemarker_version();
end get_freemarker_version;


function get_freemarker_version_number return integer
is
begin
  return ftldb_wrapper.get_freemarker_version_number();
end get_freemarker_version_number;


begin
  init();
exception
  when others then
    dbms_session.modify_package_state(dbms_session.reinitialize);
    raise_application_error(-20000, 'FTLDB initialization failed', true);
end ftldb_api;
/
