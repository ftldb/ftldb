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

create or replace package demo_dtoch_gen is

/**
 * The main procedure.
 * You can invoke it at any time to get a runnable script in the current
 * environment.
 */
function regenerate(
  in_param_list in demo_dtoch_gen_pr_nt
) return ftldb_script_ot;


-- The rest are used for FTL callbacks only.

function internal_get_columns_info(
  in_src_selectable in varchar2
) return sys_refcursor;


function internal_uk_columns_info(
  in_selectable in varchar2
) return sys_refcursor;


function internal_gen_parm_list return sys_refcursor;


end demo_dtoch_gen;
/
create or replace package body demo_dtoch_gen is


g_gen_parm_list demo_dtoch_gen_pr_nt;


function internal_get_columns_info(
  in_src_selectable in varchar2
) return sys_refcursor
is
  l_rc sys_refcursor;
begin
  open l_rc for
    select
      tc.column_name,
      case
        when cc.comments like '%@mandatory%' then 'N'
        when cc.comments like '%@nullable%' then 'Y'
        else tc.nullable
      end nullable,
      trim(replace(replace(cc.comments, '@mandatory'), '@nullable')) comments
    from user_tab_cols tc
      join user_col_comments cc
      on
        cc.table_name = tc.table_name and
        cc.column_name = tc.column_name
    where
      tc.table_name = in_src_selectable and
      tc.hidden_column = 'NO' and
      tc.virtual_column = 'NO'
    order by tc.column_id;

  return l_rc;

end;


function get_uk_name(in_selectable in varchar2) return varchar2
is
begin
  for r in (
    select
      z.constraint_name,
      count(1) over(partition by z.ord) uk_cnt
    from
      (
      select
        c.constraint_name,
        case c.constraint_type when 'P' then 1 else 2 end ord
      from user_constraints c
      where
        c.table_name = in_selectable and
        c.constraint_type in ( 'P', 'U' )
      group by c.constraint_name, c.constraint_type
      ) z
    order by z.ord
  ) loop

    if r.uk_cnt != 1 then
      raise_application_error(
        -20000,
        'Ambiguous (' || r.uk_cnt ||
          ') selection of unique constraint. The first is ' ||
          in_selectable || '.' || r.constraint_name
      );
    end if;

    return r.constraint_name;

  end loop;

  raise_application_error(
    -20000,
    'No unique key for view (or table) ' || in_selectable || ' was found.'
  );

end;


function internal_uk_columns_info(
  in_selectable in varchar2
) return sys_refcursor
is
  l_contraint_name varchar2(30) := get_uk_name(in_selectable);
  l_rc sys_refcursor;
begin
  open l_rc for
    select
      cc.column_name,
      case
        when cm.comments like '%@mandatory%' then 'N'
        when cm.comments like '%@nullable%' then 'Y'
        else tc.nullable
      end nullable
    from user_cons_columns cc
      join user_tab_cols tc
      on
        tc.table_name = cc.table_name and
        tc.column_name = cc.column_name
      join user_col_comments cm
      on
        cm.table_name = cc.table_name and
        cm.column_name = cc.column_name
    where cc.constraint_name = l_contraint_name
    order by cc.position;

  return l_rc;

end;


/**
 * Container of local routines and macros
 */
$if null $then
--%begin local_ftl_macros
<#import "ftldb_standard_ftl" as std>
<#import "ftldb_sql_ftl" as sql>

<#function get_columns_info a_selectable>
  <#return
    sql.fetch(
      "demo_dtoch_gen.internal_get_columns_info", a_selectable?upper_case
    ).hash_rows
  />
</#function>

<#function get_uk_columns_info a_selectable>
  <#return
    sql.fetch(
      "demo_dtoch_gen.internal_uk_columns_info", a_selectable?upper_case
    ).hash_rows
  />
</#function>

<#macro gen_snap_tab a_snap_tab a_selectable>
  <#local l_cols_info = get_columns_info(a_selectable)/>
  --
  <@std.indent ltab = 2>
    create table ${a_snap_tab}(
      ch_id not null,
      is_alive not null,
      <@std.indent ltab = 2>
        <#list l_cols_info as r>
          ${r.COLUMN_NAME?lower_case}<#rt/>
          <#lt/> ${(r.NULLABLE == 'N')?then('not null', 'null')},
        </#list>
      </@std.indent>
      <#local
        l_cols =
          std.to_list(
            sql.get_column(get_uk_columns_info(a_selectable), "COLUMN_NAME")
          )?lower_case
      />
      -- specification of index is out of scope
      unique(${l_cols})
    ) as
    select
      cast(1 as number(14)) ch_id,
      cast('Y' as varchar2(1)) is_alive,
      src.*
    from ${a_selectable?lower_case} src
    where 1=2
  </@std.indent>
  </>

  <#local
    l_src_comments =
      default_connection().query(
        "select tc.comments\n" +
        "from user_tab_comments tc\n" +
        "where tc.table_name = :1",
        [a_selectable?upper_case]
      ).seq_rows[0][0]
  />
  comment on table ${a_snap_tab} is 'Snapshots. ${l_src_comments} @generated ${template_name()}'
  </>
  <#list l_cols_info as r>
    <#if r.COMMENTS??>
      <#compress>
        comment on column<#rt/>
          ${a_snap_tab + "." + r.COLUMN_NAME?lower_case} is<#rt/>
          '${r.COMMENTS}'
      </>
      </#compress>
    </#if>
  </#list>
</#macro>
--%end local_ftl_macros
$end


function does_tab_exist(in_tab in varchar2) return boolean
is
begin
  for r in (
    select 'Y' from user_tables ut where ut.table_name = upper(in_tab)
  ) loop
    return true;
  end loop;
  return false;
end;


$if null $then
--%begin gen_snap_tab_ftl
<#import "demo_dtoch_gen%local_ftl_macros" as lm>
<@lm.gen_snap_tab template_args[0], template_args[1]/>
--%end gen_snap_tab_ftl
$end


function gen_snap_tab(
  in_snap_tab in varchar2, in_src_selectable in varchar2
) return ftldb_script_ot
is
begin

  return
    case does_tab_exist(in_snap_tab)
      when true then ftldb_script_ot()
      else
        ftldb_api.process(
          $$plsql_unit || '%gen_snap_tab_ftl',
          ftldb_varchar2_nt(in_snap_tab, in_src_selectable)
        )
    end
  ;
end;


$if null $then
--%begin gen_err_log_table_ftl
  <#assign a_err_log_tab = template_args[0]/>
  <#assign a_selectable = template_args[1]/>

  <#import "ftldb_standard_ftl" as std>

  <#assign
    l_col_list =
      default_connection().query(
        "select lower(tc.column_name) cn\n" +
          "from user_tab_cols tc\n" +
          "where\n" +
          "  tc.table_name = :1 and\n" +
          "  tc.hidden_column = 'NO' and\n" +
          "  tc.virtual_column = 'NO'\n" +
          "order by tc.column_id",
        [a_selectable?upper_case]
      ).col_seq[0]
  />

  <@std.indent ltab = 2>
    create table ${a_err_log_tab?lower_case}(
      ora_err_number$ number,
      ora_err_mesg$ varchar2(2000),
      ora_err_rowid$ urowid(4000),
      ora_err_optyp$ varchar2(2),
      ora_err_tag$ varchar2(2000),
      --
      <@std.format_list ltab = 1>
        ${std.to_list(l_col_list '% varchar2(4000)')}
      </@std.format_list>
    )
    </>
    comment on table ${a_err_log_tab?lower_case} is
      'Error logging table for ${a_selectable?lower_case}. @generated ${template_name()}'
    </>
  </@std.indent>
--%end gen_err_log_table_ftl
$end


function gen_err_log_table(
  in_err_log_tab in varchar2, in_selectable in varchar2
) return ftldb_script_ot
is
begin

  return
    case does_tab_exist(in_err_log_tab)
      when true then ftldb_script_ot()
      else
        ftldb_api.process(
          $$plsql_unit || '%gen_err_log_table_ftl',
            ftldb_varchar2_nt(in_err_log_tab, in_selectable)
        )
    end
  ;

end;


$if null $then
--%begin gen_diff_view_ftl
  <#assign a_diff_view = template_args[0]/>
  <#assign a_selectable = template_args[1]/>
  <#assign a_snap = template_args[2]/>

  <#import "ftldb_standard_ftl" as std>
  <#import "demo_dtoch_gen%local_ftl_macros" as lm>

  <#assign
    l_col_list =
      default_connection().query(
        "select lower(tc.column_name) cn\n" +
          "from user_tab_cols tc\n" +
          "where\n" +
          "  tc.table_name = :1 and\n" +
          "  tc.hidden_column = 'NO' and\n" +
          "  tc.virtual_column = 'NO'\n" +
          "order by tc.column_id",
        [a_selectable?upper_case]
      ).col_seq[0]
  />

create or replace view ${a_diff_view} as
select
  o.rowid upd_rid,
  nvl(n.re, 'N') is_alive,
  --
  <@std.format_list split_ptrn = '\\s*;\\s*' delim = ', ' ltab = 1>
    ${std.to_list(l_col_list 'nvl2(n.re, n.%, o.%) %' '; ')}
  </@std.format_list>
  --
from
  (
  select
    'Y' re,
    --
    <@std.format_list ltab = 1>
      ${std.to_list(l_col_list)}
    </@std.format_list>
    --
  from ${a_selectable}
  ) n
  full outer join ${a_snap} o
  on
    <@std.indent ltab = 3>
      <#list
        lm.get_uk_columns_info(a_selectable?upper_case) as cr
      >
        <#assign l_cn = cr.COLUMN_NAME?lower_case/>
        <#if cr.NULLABLE = "Y">
          (
            o.${l_cn} is not null and n.${l_cn} is not null and
            o.${l_cn} = n.${l_cn} or
            o.${l_cn} is null and n.${l_cn} is null
          )<#rt/>
        <#else/>
          o.${l_cn} = n.${l_cn}<#rt/>
        </#if>
        <#sep><#lt/> and</#sep>
      </#list>
    </@std.indent>
where
  ( nvl(o.is_alive, 'N') = 'N' and n.re = 'Y' ) or -- ins or upd
  ( o.is_alive = 'Y' and n.re is null ) or -- del
  -- upd
  ( o.is_alive = 'Y' and n.re = 'Y' ) and
  (
    <@std.format_list split_ptrn = '\\s*;\\s*' delim = ' or ' ltab = 1>
      ${std.to_list(l_col_list 'decode(n.%, o.%, 1, 0) = 0' '; ')}
    </@std.format_list>
  )
</>
comment on table ${a_diff_view} is
  'Detector of changes for ${a_selectable}. @generated ${template_name()}'
</>
--%end gen_diff_view_ftl
$end


function gen_diff_view(
  in_diff_view in varchar2, in_selectable in varchar2, in_snap in varchar2
) return ftldb_script_ot
is
begin

  return
    ftldb_api.process(
      $$plsql_unit || '%gen_diff_view_ftl',
      ftldb_varchar2_nt(in_diff_view, in_selectable, in_snap)
    )
  ;

end;


function internal_gen_parm_list return sys_refcursor
is
  l_rc sys_refcursor;
begin
  open l_rc for
    select t.src, t.snap, t.snap_errs, diff
    from table(g_gen_parm_list) t;
  return l_rc;
end;


$if null $then
--%begin gen_dtoch_pck_ftl

<#import "ftldb_standard_ftl" as std>
<#import "ftldb_sql_ftl" as sql>
<#import "demo_dtoch_gen%local_ftl_macros" as lm>

create or replace package demo_dtoch is

/**
 * @generated ${template_name()}
 */

procedure process;


end demo_dtoch;
</>

create or replace package body demo_dtoch is
<#assign
  params = sql.fetch("demo_dtoch_gen.internal_gen_parm_list").hash_rows
/>
<#list params as r>
  <#assign
    l_cols =
      sql.fetch(
        "demo_dtoch_gen.internal_get_columns_info", r.SRC?upper_case
      ).col_seq[0]
  />


procedure p_${r.SNAP}
is
begin

  delete ${r.SNAP_ERRS};

  merge into ${r.SNAP} d
  using ${r.DIFF} s
  on ( d.rowid = s.upd_rid )
  when not matched then
    insert(
      ch_id, is_alive,
      <@std.format_list ltab = 1>
        ${std.to_list(l_cols)?lower_case}
      </@std.format_list>
    ) values(
      demo_change_seq.nextval, 'Y',
      <@std.format_list ltab = 1>
        ${std.to_list(l_cols, "s.%")?lower_case}
      </@std.format_list>
    )
  when matched then
    update set
      d.ch_id = demo_change_seq.nextval, d.is_alive = s.is_alive,
      <@std.format_list ltab = 1>
        ${std.to_list(l_cols, "d.% = s.%")?lower_case}
      </@std.format_list>
  log errors into ${r.SNAP_ERRS}(
    to_char(systimestamp, 'yyyy-mm-dd hh24:mi:ss.ff')
  ) reject limit unlimited;

end;
</#list>


procedure process
is
begin
  <#list params as r>
  p_${r.SNAP}();
  </#list>
end;


end demo_dtoch;
</>

--%end gen_dtoch_pck_ftl
$end


function gen_dtoch_pck(
  in_param_list in demo_dtoch_gen_pr_nt
) return ftldb_script_ot
is
  l_ret ftldb_script_ot;
begin
  g_gen_parm_list := in_param_list;
  l_ret := ftldb_api.process($$plsql_unit || '%gen_dtoch_pck_ftl');
  g_gen_parm_list := null;
  return l_ret;
end;


function regenerate(
  in_param_list in demo_dtoch_gen_pr_nt
) return ftldb_script_ot
is
  l_ret ftldb_script_ot := ftldb_script_ot();
begin

  for r in (
    select t.src, t.snap, t.snap_errs, diff
    from table(in_param_list) t
  ) loop

    l_ret.append(gen_snap_tab(r.snap, r.src));
    l_ret.append(gen_err_log_table(r.snap_errs, r.src));
    l_ret.append(gen_diff_view(r.diff, r.src, r.snap));

  end loop;

  l_ret.append(gen_dtoch_pck(in_param_list));

  return l_ret;
end;


end demo_dtoch_gen;
/
