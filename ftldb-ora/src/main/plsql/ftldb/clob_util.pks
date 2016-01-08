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

create or replace package clob_util authid current_user as
/**
 * This package contains methods for manipulating CLOBs as bodies of
 * SQL statements. The methods of this package implement some of script_ot
 * functionality.
 * @headcom
 */


/**
 * Creates a temporary CLOB in Buffer Cache using the specified content.
 *
 * @param  in_content  the content of the CLOB to be created (optional)
 * @return             the CLOB locator
 */
function create_temporary(in_content in varchar2 := '') return clob;


/**
 * Writes the specified string into the given CLOB with the specified indent.
 *
 * @param  io_clob    the CLOB locator
 * @param  in_string  the string to be written
 * @param  in_indent  the indent size (if not null then start a new line)
 */
procedure put(
  io_clob in out nocopy clob,
  in_string in varchar2,
  in_indent in natural := null
);


/**
 * Writes the specified string into the given CLOB with the specified indent and
 * adds the LF character.
 *
 * @param  io_clob    the CLOB locator
 * @param  in_string  the string to be written (optional)
 * @param  in_indent  the indent size (if not null then start a new line)
 */
procedure put_line(
  io_clob in out nocopy clob,
  in_string in varchar2 := '',
  in_indent in natural := null
);


/**
 * Appends the specified text to the given CLOB with the specified indent for
 * each of its lines.
 *
 * @param  io_clob    the CLOB locator
 * @param  in_text    the text to be written
 * @param  in_indent  the indent size (if not null then start a new line)
 */
procedure append(
  io_clob in out nocopy clob,
  in_text in clob,
  in_indent in natural := null
);


/**
 * Trims the boundary blank lines.
 *
 * @param  io_clob  the CLOB locator
 * @return          the refined CLOB
 */
function trim_blank_lines(in_clob in clob) return clob;


/**
 * Joins the elements of the specified collection into a single CLOB using
 * the specified delimiter.
 *
 * Optionally deletes blank lines at the boundaries of each CLOB and places
 * the delimiter on a new line. This option may be used for joining SQL
 * statements and separating them by the slash character ('/').
 *
 * @param  in_clobs          the collection of CLOB locators
 * @param  in_delim          the delimiter for joining CLOBs
 * @param  in_final_delim    if true puts the delimiter at the end
 * @param  in_refine_lines   if true trims boundary blank lines and puts
 *                           the delimiter on a new line
 * @return                   the resulting CLOB
 */
function join(
  in_clobs in clob_nt,
  in_delim in varchar2 := '',
  in_final_delim in boolean := false,
  in_refine_lines in boolean := false
) return clob;


/**
 * Splits the given CLOB into lines.
 *
 * @param  in_clob  the CLOB locator
 * @return          an array of lines (compatible with DBMS_SQL)
 */
function split_into_lines(in_clob in clob) return dbms_sql.varchar2a;


/**
 * Splits the given CLOB into pieces by the specified delimiter.
 *
 * @param  in_clob         the CLOB locator
 * @param  in_delim_ptrn   the delimiter regexp pattern
 * @param  in_regexp_mdfr  the regexp modifiers (e.g. i, c, n, m)
 * @param  in_trim_lines   if true trims boundary blank lines
 * @return                 a table of CLOBs
 */
function split_into_pieces(
  in_clob in clob,
  in_delim_ptrn in varchar2,
  in_regexp_mdfr in varchar2 := '',
  in_trim_lines in boolean := false
) return clob_nt;


/**
 * Prints the given CLOB to the DBMS_OUTPUT buffer with the ending character.
 *
 * @param  in_clob  the CLOB locator
 * @param  in_eof   the ending character (optional)
 */
procedure show(in_clob in clob, in_eof in varchar2 := '');


/**
 * Executes the given CLOB as an SQL statement.
 *
 * @param  in_clob  the CLOB locator
 * @param  in_echo  if true prints the CLOB to the DBMS_OUTPUT buffer
 */
procedure exec(
  in_clob in clob,
  in_echo in boolean := false
);


end clob_util;
/
