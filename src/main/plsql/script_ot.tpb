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

create or replace type body script_ot as


constructor function script_ot(
  statements in clob_nt := clob_nt()
) return self as result
is
  c_invalid_argument_num constant number := -20100;
begin
  if statements is null or
      nvl(statements.last(), 0) != statements.count()
  then
    raise_application_error(
      c_invalid_argument_num, 'input collection is uninitialized or sparse'
    );
  end if;
  self.statements := statements;
  return;
end script_ot;


constructor function script_ot(
  in_clob in clob,
  in_stmt_delim in varchar2 := '/'
) return self as result
is
begin
  self := script_ot(
    clob_util.split_into_pieces(in_clob, in_stmt_delim, in_trim_spaces => true)
  );
  return;
end script_ot;


member function to_clob(
  self in script_ot,
  in_stmt_delim varchar2 := '/'
) return clob
is
begin
  return
    clob_util.join(
      self.statements, in_stmt_delim, in_final_delim => true,
      in_refine_spaces => true
    );
end to_clob;


member procedure append(
  self in out nocopy script_ot,
  in_statement in clob
)
is
begin
  self.statements.extend();
  self.statements(self.statements.last()) := in_statement;
end append;


member procedure show(
  self in script_ot,
  in_idx in positiven
)
is
begin
  clob_util.show(self.statements(in_idx), '/');
end show;


member procedure exec(
  self in script_ot,
  in_idx in positiven,
  in_echo in boolean := false
)
is
begin
  clob_util.exec(self.statements(in_idx), in_echo);
end exec;


member procedure append(
  self in out nocopy script_ot,
  in_script in script_ot
)
is
  l_i pls_integer := in_script.statements.first();
begin
  while l_i is not null loop
    append(in_script.statements(l_i));
    l_i := in_script.statements.next(l_i);
  end loop;
end append;


member procedure show(self in script_ot)
is
  l_i pls_integer := self.statements.first();
begin
  while l_i is not null loop
    show(l_i);
    l_i := self.statements.next(l_i);
  end loop;
end show;


member procedure exec(
  self in script_ot,
  in_echo in boolean := false,
  in_suppress_errors in boolean := false
)
is
  c_execution_error_num constant number := -20000;
  c_execution_error_msg constant varchar2(2000) := 'error ' ||
    case when in_suppress_errors then 'suppressed' else 'occurred' end ||
    ' in statement #%d (%s): %s';
  l_i pls_integer := self.statements.first();
  l_statement_piece varchar2(60);
  l_error_msg varchar2(2000);
begin
  while l_i is not null loop
    begin
      exec(l_i, in_echo);
    exception
      when others then
        l_statement_piece :=
          replace(
            to_char(substr(self.statements(l_i), 1, 50)), chr(10), ' '
          ) ||
          case
            when dbms_lob.getlength(self.statements(l_i)) > 50
            then '...'
          end;

        l_error_msg :=
          utl_lms.format_message(
            c_execution_error_msg, l_i, l_statement_piece, sqlerrm
          );

        if not in_suppress_errors then
          raise_application_error(c_execution_error_num, l_error_msg);
        end if;

        if in_echo then
          dbms_output.put_line(l_error_msg);
        end if;
    end;

    l_i := self.statements.next(l_i);
  end loop;
end exec;


end;
/
