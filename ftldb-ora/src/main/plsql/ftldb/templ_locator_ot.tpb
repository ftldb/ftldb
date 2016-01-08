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

create or replace type body templ_locator_ot as


member function get_type_name return varchar2
is
  l_type_code pls_integer;
  l_type anytype;
  l_prec pls_integer;
  l_scale pls_integer;
  l_len pls_integer;
  l_csid pls_integer;
  l_csfrm pls_integer;
  l_schema_name varchar2(30 byte);
  l_type_name varchar2(30 byte);
  l_version varchar2(45 byte);
  l_numelems pls_integer;
begin
  l_type_code := anydata.convertobject(self).gettype(l_type);
  l_type_code := l_type.getinfo(
    l_prec, l_scale, l_len, l_csid, l_csfrm, l_schema_name, l_type_name,
    l_version, l_numelems
  );
  return '"' || l_schema_name || '"."' || l_type_name || '"';
end get_type_name;


member function xml_encode return xmltype
is
begin
  return
    xmltype('<LOCATOR/>')
      .appendchildxml(
        '/*[1]',
        xmltype(
          '<TYPE>' ||
            utl_i18n.escape_reference(get_type_name()) ||
          '</TYPE>'
        )
      )
      .appendchildxml(
        '/*[1]',
        xmltype('<INSTANCE/>').appendchildxml('/*[1]', xmltype(self))
      );
end xml_encode;


static function xml_decode(in_locator_xml xmltype) return templ_locator_ot
is
  c_type_name constant varchar2(65 byte) :=
    utl_i18n.unescape_reference(
      in_locator_xml.extract('/LOCATOR/TYPE/text()').getstringval()
    );
  c_xml_decoder_call constant varchar2(128 byte) :=
    'declare x xmltype := :1; v %type%; begin x.toobject(v); :2 := v; end;';

  l_locator templ_locator_ot;

  c_type_ctx constant pls_integer := 7;
  l_schema varchar2(30 byte);
  l_part1 varchar2(30 byte);
  l_part2 varchar2(30 byte);
  l_dblink varchar2(128 byte);
  l_part1_type varchar2(30 byte);
  l_object_number number;
begin
  -- Assert the decoded type exists
  dbms_utility.name_resolve(
    c_type_name, c_type_ctx,
    l_schema, l_part1, l_part2, l_dblink, l_part1_type, l_object_number
  );

  execute immediate replace(c_xml_decoder_call, '%type%', c_type_name)
  using in in_locator_xml.extract('/LOCATOR/INSTANCE/*[1]'), out l_locator;

  return l_locator;
end xml_decode;


end;
/
