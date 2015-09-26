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

create or replace package source_util authid current_user as
/**
 * This package contains methods for manipulating sources stored in the data
 * dictionary. It allows to use object bodies as containers for code templates.
 * @headcom
 */

-- The list of object types where templates can be stored and extracted from.
gc_supported_obj_types constant varchar2_nt := varchar2_nt(
  'FUNCTION', 'PROCEDURE', 'PACKAGE', 'VIEW', 'TYPE', 'TRIGGER', 'JAVA SOURCE',
  'JAVA RESOURCE'
);

-- The exception raised when an argument value is invalid.
e_invalid_argument exception;
pragma exception_init(e_invalid_argument, -20100);
gc_invalid_argument_num constant number := -20100;

-- The exception raised when a name cannot be resolved to an object.
e_name_not_resolved exception;
pragma exception_init(e_name_not_resolved, -20101);
gc_name_not_resolved_num constant number := -20101;
gc_name_not_resolved_msg constant varchar2(2000) :=
  'name %s cannot be resolved';
gc_looping_synonym_chain_msg constant varchar2(2000) :=
  'synonym %s references to a looping chain';
gc_dblink_over_dblink_msg constant varchar2(2000) :=
  'remote synonym %s references to another remote database %s';

-- The exception raised when an object is not found.
e_object_not_found exception;
pragma exception_init(e_object_not_found, -20102);
gc_object_not_found_num constant number := -20102;
gc_object_not_found_msg constant varchar2(2000) :=
  'object %s of type %s is not found';

-- The exception raised when a source for an object is not found.
e_source_not_found exception;
pragma exception_init(e_source_not_found, -20103);
gc_source_not_found_num constant number := -20103;
gc_source_not_found_msg constant varchar2(2000) :=
  'source for object %s of type %s is not found';

-- The exception raised when a section in a container is not found.
e_section_not_found exception;
pragma exception_init(e_section_not_found, -20104);
gc_section_not_found_num constant number := -20104;
gc_section_not_found_msg constant varchar2(2000) :=
  '%d occurrence of section bounded between regular expressions "%s" and ' ||
  '"%s" is not found in container %s';
gc_ncmp_section_not_found_msg constant varchar2(2000) :=
  'non-compiled section is not found in container %s';
gc_named_section_not_found_msg constant varchar2(2000) :=
  '%d occurrence of named section %s is not found in container %s';


/**
 * Executes the specified scalar query and returns the resulting LONG value
 * as a CLOB. This method is an analog of UTL_XML.LON2CLOB, but works with any
 * table or view.
 *
 * @param  in_sql   the SQL query to be executed
 * @param  in_vars  the list of the bind variables
 * @param  in_vals  the list of the corresponding bind variable values
 * @return          the resulting LONG value as a CLOB
 *
 * @throws  e_invalid_argument  if the input collections are inconsistent or
 *                              the query doesn't return a single LONG column
 * @throws  no_data_found       if the query returns no rows
 * @throws  too_many_rows       if the query returns more than one row
 */
function long2clob(
  in_sql in varchar2,
  in_vars in varchar2_nt := varchar2_nt(),
  in_vals in varchar2_nt := varchar2_nt()
) return clob;


/**
 * Resolves the specified full name to the referenced object's owner, name,
 * dblink (if any) and type.
 *
 * @param  in_ora_name  the name to be resolved (case-sensitive when quoted)
 * @param  out_owner    the referenced object's owner
 * @param  out_obj_name the referenced object's name
 * @param  out_dblink   the referenced object's dblink
 * @param  out_type     the referenced object's type
 *
 * @throws  e_invalid_argument   if the name is not a correct Oracle name
 * @throws  e_name_not_resolved  if the name cannot be resolved
 */
procedure resolve_ora_name(
  in_ora_name in varchar2,
  out_owner out varchar2,
  out_obj_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
);


/**
 * Resolves the specified source template name, which is similar to an Oracle
 * name, but may contain a section part: [SCHEMA.]OBJNAME[%SECNAME][@DBLINK].
 *
 * @param  in_src_name    the name to be resolved (case-sensitive when quoted)
 * @param  out_owner      the referenced object's owner
 * @param  out_obj_name   the referenced object's name
 * @param  out_sec_name   the referenced section's name
 * @param  out_dblink     the referenced object's dblink
 * @param  out_type       the referenced object's type
 */
procedure resolve_src_name(
  in_src_name in varchar2,
  out_owner out varchar2,
  out_obj_name out varchar2,
  out_sec_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
);


/**
 * Resolves the specified long name. Converts it to a short name, then resolves
 * as an Oracle name.
 *
 * @param  in_long_name   the name to be resolved (case-sensitive, not quoted)
 * @param  out_owner      the referenced object's owner
 * @param  out_obj_name   the referenced object's name
 * @param  out_dblink     the referenced object's dblink
 * @param  out_type       the referenced object's type
 */
procedure resolve_long_name(
  in_long_name in varchar2,
  out_owner out varchar2,
  out_obj_name out varchar2,
  out_dblink out varchar2,
  out_type out varchar2
);


/**
 * Returns the specified object's last modification time.
 *
 * @param  in_owner     the object's owner (case-sensitive)
 * @param  in_obj_name  the object's name (case-sensitive)
 * @param  in_dblink    the object's dblink (case-insensitive)
 * @param  in_type      the object's type (case-insensitive)
 * @return              the object's last modification time
 *
 * @throws  e_invalid_argument  if the object's owner, name or type is not
 *                              specified or the type is not supported
 * @throws  e_object_not_found  if the object is not found in the data
 *                              dictionary
 */
function get_obj_timestamp(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return timestamp;


/**
 * Extracts the specified object's source from the data dictionary. This method
 * is an analog of DBMS_METADATA.GET_DDL, but doesn't need SELECT_CATALOG_ROLE
 * to access objects in different schemas.
 *
 * @param  in_owner     the object's owner (case-sensitive)
 * @param  in_obj_name  the object's name (case-sensitive)
 * @param  in_dblink    the object's dblink (case-insensitive)
 * @param  in_type      the object's type (case-insensitive)
 * @return              the object's source as a CLOB
 *
 * @throws  e_invalid_argument  if the object's owner, name or type is not
 *                              specified or the type is not supported
 * @throws  e_source_not_found  if the source is not found in the data
 *                              dictionary
 */
function get_obj_source(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return clob;


/**
 * Extracts a section bounded between the specified regular expressions from
 * the specified container.
 *
 * @param  in_container        the container (CLOB)
 * @param  in_start_pattern    the starting boundary regexp pattern
 * @param  in_end_pattern      the ending boundary regexp pattern
 * @param  in_keep_boundaries  if true includes boundaries in the result
 * @param  in_lazy_search      if true does the lazy search
 * @param  in_occurrence       the occurrence of the searched pattern
 * @return                     the sought section as a CLOB
 *
 * @throws  e_invalid_argument   if the occurrence is not equal to 1 for the
 *                               greedy search
 * @throws  e_section_not_found  if the section is not found
 */
function extract_section_from_clob(
  in_container in clob,
  in_start_pattern in varchar2,
  in_end_pattern in varchar2,
  in_keep_boundaries in boolean := false,
  in_lazy_search in boolean := false,
  in_occurrence in positiven := 1
) return clob;


/**
 * Extracts a section bounded between the specified regular expressions from
 * the specified object's source.
 *
 * @param  in_owner            the object's owner (case-sensitive)
 * @param  in_obj_name         the objects's name (case-sensitive)
 * @param  in_dblink           the object's name (case-insensitive)
 * @param  in_type             the object's name (case-insensitive)
 * @param  in_start_pattern    the starting boundary regexp pattern
 * @param  in_end_pattern      the ending boundary regexp pattern
 * @param  in_keep_boundaries  if true includes boundaries in the result
 * @param  in_lazy_search      if true does the lazy search
 * @param  in_occurrence       the occurrence of the sought pattern
 * @return                     the sought section as a CLOB
 *
 * @throws  e_invalid_argument   if the occurrence is not equal to 1 for the
 *                               greedy search
 * @throws  e_section_not_found  if the section is not found
 */
function extract_section_from_obj_src(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2,
  in_start_ptrn in varchar2,
  in_end_ptrn in varchar2,
  in_keep_boundaries in boolean := false,
  in_lazy_search in boolean := false,
  in_occurrence in positiven := 1
) return clob;


/**
 * Extracts a section bounded between the specified regular expressions from
 * the specified container's source.
 *
 * @param  in_container_name   the container's name (case-sensitive if quoted)
 * @param  in_start_pattern    the starting boundary regexp pattern
 * @param  in_end_pattern      the ending boundary regexp pattern
 * @param  in_keep_boundaries  if true includes boundaries in the result
 * @param  in_lazy_search      if true does the lazy search
 * @param  in_occurrence       the occurrence of the sought pattern
 * @return                     the sought section as a CLOB
 *
 * @throws  e_invalid_argument   if the occurrence is not equal to 1 for the
 *                               greedy search
 * @throws  e_section_not_found  if the section is not found
 */
function extract_section_from_obj_src(
  in_container_name in varchar2,
  in_start_ptrn in varchar2,
  in_end_ptrn in varchar2,
  in_keep_boundaries in boolean := false,
  in_lazy_search in boolean := false,
  in_occurrence in positiven := 1
) return clob;


/**
 * Extracts a non-compiled section bounded between two conditional compilation
 * directives from the specified object's source. Example:
 * <pre>
 *   $if false $then
 *   the sought section
 *   $end
 * </pre>
 * The syntax is case- and space-insensitive. The search is greedy.
 *
 * @param  in_owner     the object's owner (case-sensitive)
 * @param  in_obj_name  the objects's name (case-sensitive)
 * @param  in_dblink    the object's name (case-insensitive)
 * @param  in_type      the object's name (case-insensitive)
 * @return              the sought section without boundaries as a CLOB
 *
 * @throws  e_section_not_found  if the section is not found
 */
function extract_noncompiled_section(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2
) return clob;


/**
 * Extracts a non-compiled section bounded between two conditional compilation
 * directives from the specified container's source. Example:
 * <pre>
 *   $if false $then
 *   the sought section
 *   $end
 * </pre>
 * The syntax is case- and space-insensitive. The search is greedy.
 *
 * @param  in_container_name  the container's name (case-sensitive if quoted)
 * @return                    the sought section without boundaries as a CLOB
 *
 * @throws  e_section_not_found  if the section is not found
 */
function extract_noncompiled_section(
  in_container_name in varchar2
) return clob;


/**
 * Extracts a named section bounded between two special comments from the
 * specified object's source. Example:
 * <pre>
 *   --%begin my_template
 *   the sought section
 *   --%end my_template
 * </pre>
 * The syntax is case- and space-insensitive. The search is lazy.
 *
 * @param  in_owner         the object's owner (case-sensitive)
 * @param  in_obj_name      the objects's name (case-sensitive)
 * @param  in_dblink        the object's name (case-insensitive)
 * @param  in_type          the object's name (case-insensitive)
 * @param  in_section_name  the section's name (case-insensitive)
 * @param  in_occurrence    the occurrence of the sought section
 * @return                  the sought section without boundaries as a CLOB
 *
 * @throws  e_section_not_found  if the section is not found
 */
function extract_named_section(
  in_owner in varchar2,
  in_obj_name in varchar2,
  in_dblink in varchar2,
  in_type in varchar2,
  in_section_name in varchar2,
  in_occurrence in positiven := 1
) return clob;


/**
 * Extracts a named section bounded between two special comments from the
 * specified container's source. Example:
 * <pre>
 *   --%begin my_template
 *   the sought section
 *   --%end my_template
 * </pre>
 * The syntax is case- and space-insensitive. The search is lazy.
 *
 * @param  in_container_name  the container's name (case-sensitive if quoted)
 * @param  in_section_name    the section's name (case-insensitive)
 * @param  in_occurrence      the occurrence of the sought section
 * @return                    the sought section without boundaries as a CLOB
 *
 * @throws  e_section_not_found  if the section is not found
 */
function extract_named_section(
  in_container_name in varchar2,
  in_section_name in varchar2,
  in_occurrence in positiven := 1
) return clob;


/**
 * Seeks a section bounded between the specified regular expressions in
 * the specified container and replaces it with the specified replacement.
 *
 * @param  in_container        the container (CLOB)
 * @param  in_start_pattern    the starting boundary regexp pattern
 * @param  in_end_pattern      the ending boundary regexp pattern
 * @param  in_replacement      the replacement
 * @param  in_keep_boundaries  if true includes boundaries in the result
 * @param  in_lazy_search      if true does the lazy search
 * @param  in_occurrence       the occurrence of the sought pattern
 * @return                     the resulting CLOB
 *
 * @throws  e_invalid_argument   if the occurrence is not equal to 1 for the
 *                               greedy search or if the boundaries are to be
 *                               kept and the starting boundary pattern contains
 *                               unmatched parentheses or more than 7 pairs of
 *                               matched parentheses
 * @throws  e_section_not_found  if the section is not found
 */
function replace_section_in_clob(
  in_container in clob,
  in_start_ptrn in varchar2,
  in_end_ptrn in varchar2,
  in_replacement in clob,
  in_keep_boundaries in boolean := false,
  in_lazy_search in boolean := false,
  in_occurrence in positiven := 1
) return clob;


/**
 * Seeks a named section bounded between two special comments in the specified
 * container and replaces it to the specified replacement. Example:
 * <pre>
 *   --%begin my_template
 *   the sought section
 *   --%end my_template
 * </pre>
 * The syntax is case- and space-insensitive. The search is lazy.
 *
 * @param  in_container        the container (CLOB)
 * @param  in_section_name     the section's name (case-insensitive)
 * @param  in_replacement      the replacement
 * @param  in_keep_boundaries  if true keeps the boundaries
 * @param  in_occurrence       the occurrence of the sought section
 * @return                     the resulting CLOB
 *
 * @throws  e_section_not_found  if the section is not found
 */
function replace_named_section_in_clob(
  in_container clob,
  in_section_name varchar2,
  in_replacement clob,
  in_keep_boundaries in boolean := false,
  in_occurrence in positiven := 1
) return clob;


end source_util;
/
