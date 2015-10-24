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

create or replace package body ftldb_admin as


/**
 * Switches privileges on/off for the specified list of users.
 */
procedure switch_privileges(
  in_enable boolean,
  in_grantees varchar2_nt
)
is
  e_cannot_revoke_absent_priv exception;
  pragma exception_init(e_cannot_revoke_absent_priv, -1927);

  l_action varchar2(6 byte) :=
    case when in_enable then 'grant' else 'revoke' end;
  l_direction varchar2(4 byte) :=
    case when in_enable then 'to' else 'from' end;
begin
  if in_grantees is null or in_grantees.count() = 0 then
    return;
  end if;

  for r in (
    select
      l_action || ' execute on ' ||
      case when o.object_type = 'JAVA RESOURCE' then 'java resource ' end ||
      '"' || sys_context('userenv', 'current_schema') || '"."' ||
      case
        when o.object_name like '/%' then dbms_java.longname(o.object_name)
        else o.object_name
      end ||
      '" ' ||
      l_direction || ' ' || dbms_assert.enquote_name(value(u)) as statement
    from
      table(in_grantees) u, user_objects o
    where (
        o.object_type in ('FUNCTION', 'PROCEDURE', 'PACKAGE', 'TYPE') and
        o.object_name not in ($$plsql_unit)
      ) or (
        o.object_type in ('JAVA CLASS', 'JAVA RESOURCE') and
        regexp_substr(dbms_java.longname(o.object_name), '^[^/]+/') in (
          'ftldb/', 'freemarker/'
        )
      )
  ) loop
    begin
      execute immediate r.statement;
    exception
      when e_cannot_revoke_absent_priv then
        null;
      when others then
        raise_application_error(
          -20000,
          'execution failed: ' || r.statement || chr(10) ||
          sqlerrm
        );
    end;
  end loop;
end switch_privileges;


procedure grant_privileges(in_grantees varchar2_nt)
is
begin
  switch_privileges(true, in_grantees);
end grant_privileges;


procedure grant_privileges(in_grantee varchar2)
is
begin
  grant_privileges(varchar2_nt(in_grantee));
end grant_privileges;


procedure revoke_privileges(in_grantees varchar2_nt)
is
begin
  switch_privileges(false, in_grantees);
end revoke_privileges;


procedure revoke_privileges(in_grantee varchar2)
is
begin
  revoke_privileges(varchar2_nt(in_grantee));
end revoke_privileges;


end ftldb_admin;
/
