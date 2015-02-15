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

create or replace type script_ot authid current_user as object (
/**
 * A script is a collection of statements represented as CLOBs.
 *
 * This type contains methods for constructing a script, filling it with
 * statements, executing, and printing it to the DBMS_OUTPUT buffer.
 * @headcom 
 */

-- The collection of statements.
statements clob_nt,


/**
 * Constructs a new script from the specified collection of statements.
 * Overrides the default constructor.
 *
 * @param  statements  the collection of statements (optional)
 * @return             a script object
 */
constructor function script_ot(
  statements in clob_nt := clob_nt()
) return self as result,


/**
 * Constructs a new script from the specified CLOB by splitting it into
 * a collection of statements.
 *
 * @param  in_clob        the CLOB of statements
 * @param  in_stmt_delim  the delimiter
 * @return                a script object
 */
constructor function script_ot(
  in_clob in clob,
  in_stmt_delim in varchar2 := '/'
) return self as result,


/**
 * Returns the script as a single CLOB delimited by the specified string.
 * @param  in_stmt_delim  the delimiter
 * @return                the script combined to a single CLOB
 */
member function to_clob(
  self in script_ot,
  in_stmt_delim in varchar2 := '/'
) return clob,


/**
 * Appends the specified statement to the object.
 *
 * @param  in_statement  the statement to be added
 */
member procedure append(
  self in out nocopy script_ot,
  in_statement in clob
),


/**
 * Prints the statement with the specified index to the DBMS_OUTPUT buffer.
 *
 * @param  in_idx  the index of the statement to be printed
 */
member procedure show(
  self in script_ot,
  in_idx in positiven
),


/**
 * Executes the statement with the specified index.
 *
 * @param  in_idx   the index of the statement to be executed
 * @param  in_echo  if true prints the statement to the DBMS_OUTPUT buffer
 */
member procedure exec(
  self in script_ot,
  in_idx in positiven,
  in_echo in boolean := false
),


/**
 * Appends the specified script to the object.
 *
 * @param  in_script  the script to be added
 */
member procedure append(
  self in out nocopy script_ot,
  in_script in script_ot
),


/**
 * Prints the script to the DBMS_OUTPUT buffer.
 */
member procedure show(self in script_ot),


/**
 * Executes the script.
 *
 * @param  in_echo             if true prints the script to the DBMS_OUTPUT
 *                             buffer
 * @param  in_suppress_errors  if true suppresses the occurring errors
 */
member procedure exec(
  self in script_ot,
  in_echo in boolean := false,
  in_suppress_errors in boolean := false
)


)
/
