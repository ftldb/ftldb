FTLDB
=====

<img src="https://raw.github.com/ftldb/ftldb/master/logo.png" align="right" width="250px" />

An integration of the [FreeMarker](http://freemarker.org) template engine into
[Oracle Database](http://oracle.com/database/index.html) for easier server-side
code generation.

Allows you to create, store and execute templates written in FTL inside a
database. You can generate any kind of SQL/DML/DDL statements or stored program
units using metadata retrieved from queries and calls. Instead of composing
complex string expressions full of quotes and concatenation operators (as you
may currently do) just write and compile plain SQL or PL/SQL code flavored with
FTL macros in you favorite IDE with the support of its content/code assist
features.

Not an Oracle user? No problem. FTLDB also suits for *client-side* code
generation for [PostgreSQL](http://postgresql.org), [MySQL](http://mysql.com),
[DB2](http://ibm.com/software/data/db2) and any other RDBMS providing a JDBC
driver.


Table of contents
-----------------
  - [Intro](#intro)
  - [Compatibility](#compatibility)
  - [Usage comparison](#usage-comparison)
  - [Security](#security)
  - [Installation](#installation)
  - [Demo](#demo)
  - [Building the project](#building-the-project)
  - [Authors](#authors)
  - [License](#license)
  - [Sponsors](#sponsors)


Intro
-----

While developing a database application you may encounter the need of code
generation, a technique of composing code programmatically rather than manually
using different sources of metadata.

This need may be caused by working with a priori unknown conditions or
environment, e.g. when you construct an SQL query based on user filters and
grouping columns selection, or when you adapt your application for working on
databases of different vendors, versions and editions. Another reason is
following the [DRY](http://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
principle, e.g. when you work with a finite set of similar data structures, to
which a common processing algorithm is applied, and you are able to implement
one template and generate many slightly different procedures from it.

The code generation problem may be solved in two ways:

  1. By using a common programming language such as PL/SQL or Java: here the
     *generator* code is primary, while the *generated* code is secondary,
     hidden behind the former and hardly readable.

  2. By using a special template language: here the *generated* code is primary
     and easily readable from a template, while the *generator* code is
     secondary and takes much less attention.

[FreeMarker](http://freemarker.org) is a Java-based template engine that allows
to solve the code generation problem in the second way with a simple template
language called FTL.

> **Notice**: FreeMarker is not the only possible option. We have also tried its
> closest competitor [Velocity](http://velocity.apache.org) and succeeded, but
> the project seems frozen and its language is not as convenient as FTL. See an
> old [feature comparison](http://freemarker.org/fmVsVel.html) for more details.

FTLDB is an enhancement of FreeMarker for working with databases via JDBC. It
provides FTL methods for retrieving data from a database with queries and calls.
It also provides extra PL/SQL functionality for working in Oracle Database.

FTLDB may work either as a database application or as an external utility. We
call it *server-side* and *client-side* mode correspondingly.

In the server-side mode templates are stored inside a database in program unit
bodies as plain text. FTLDB runs on the embedded JVM, reads templates and
complementary data from the database, processes the templates and returns the
result as an object, which can be saved to a table or run immediately as a
script. Thus, you need only a database, but necessarily with Java support.

In the client-side mode templates are stored in files on a client, e.g.
developer's computer. FTLDB runs on the local JVM, reads templates, connects to
a database, reads complementary data from it, processes the templates and saves
the result into an output file, which can be run later with a database utility
such as [SQL*Plus](http://en.wikipedia.org/wiki/SQL*Plus). Thus, you need not
only a database but also a JRE, a JDBC driver and a database utility installed
on the client.

The server-side mode looks more integral, since it allows to store templates,
metadata and the resulting objects together and doesn't require extra machine
and software.

However, the client-side mode is more universal, since it works with almost any
RDBMS and provides a command line launcher for FreeMarker, which is useful even
without database features, e.g. for combining multiple files into a single
installation script.


Compatibility
-------------

The server-side mode needs an embedded 1.4 compliant JVM and a PL/SQL compiler
of version 10 or higher. Thus, it works in Oracle Database 10g, 11g and 12c (all
editions except for XE).

The client-side mode suits for any versions of Oracle Database, as well as
PostgreSQL, MySQL, DB2 and other RDBMSs, which provide a JDBC driver.


Usage comparison
----------------

As mentioned above, the code generation problem can usually be solved
server-side in pure PL/SQL or Java. But in many cases, when a lot of static
code could be isolated and copied to a template unchanged, a solution written
using FTLDB would be much more readable and hence supportable than the former.
We'll show you the difference in possible solutions on the following problem.

> **Problem**: Suppose you need to create a new `orders` table, which must be
> partitioned by the `shop_id` column values into 4 regions (`east`, `north`,
> `south`, `west`) according to the location of shops where orders are placed.
> The exact partitioning clause is initially unknown and composed from the
> result of a query to the `shops` table.

Let's look at three examples (fragments of code) that do the same - generate,
print and execute a script for creating the table.

#### Pure PL/SQL approach

A fragment of the `generator` package:
```sql
create or replace package body generator as

cursor cur_partitions is
  select
    t.region name,
    listagg(t.shop_id, ', ')
      within group (order by t.shop_id) vals
  from shops t
  group by t.region
  order by t.region;

procedure gen_orders_plsql
is
  l_scr clob;
begin
  l_scr :=
    'create table orders (' || chr(10) ||
    '  order_id integer not null primary key,' || chr(10) ||
    '  customer_id integer not null,' || chr(10) ||
    '  shop_id integer not null,' || chr(10) ||
    '  order_date date not null,' || chr(10) ||
    '  status varchar2(10) not null' || chr(10) ||
    ')' || chr(10) ||
    'partition by list(shop_id) (';

  for r in cur_partitions loop
    l_scr := l_scr ||
      case when cur_partitions%rowcount > 1 then ',' end || chr(10) ||
      '  partition ' || r.name || ' values (' || r.vals || ')';
  end loop;

  l_scr := l_scr || chr(10) || ')';

  dbms_output.put_line(l_scr);
  dbms_output.put_line('/');
  execute immediate l_scr;

  l_scr := 'comment on table orders is ''Orders partitioned by region.''';

  dbms_output.put_line(l_scr);
  dbms_output.put_line('/');
  execute immediate l_scr;

end gen_orders_plsql;

...

end generator;
/
```

The table creation PL/SQL script:
```sql
begin
  generator.gen_orders_plsql();
end;
/
```

#### Server-side FTLDB

A fragment of the `generator` package:
```sql
create or replace package body generator as

...

function get_partitions return sys_refcursor
is
  l_rc sys_refcursor;
begin
  open l_rc for
    select
      t.region name,
      listagg(t.shop_id, ', ')
        within group (order by t.shop_id) vals
    from shops t
    group by t.region
    order by t.region;
  return l_rc;
end get_partitions;

$if false $then
--%begin orders_ftl

<#import "ftldb.sql_ftl" as sql/>
<#assign partitions = sql.fetch('generator.get_partitions')/>

create table orders (
  order_id integer not null primary key,
  customer_id integer not null,
  shop_id integer not null,
  order_date date not null,
  status varchar2(10) not null
)
partition by list(shop_id) (
<#list partitions.hash_rows as p>
  partition ${p.NAME} values (${p.VALS})<#if p_has_next>,</#if>
</#list>
)
</>

comment on table orders is 'Orders partitioned by region.'
</>

--%end orders_ftl
$end

function gen_orders_ftldb return ftldb.script_ot
is
begin
  return ftldb.ftldb_api.process('generator%orders_ftl');
end gen_orders_ftldb;

end generator;
/
```

The table creation PL/SQL script:
```sql
begin
  generator.gen_orders_ftldb().exec(true);
end;
/
```

#### Client-side FTLDB

Content of the `orders.ftl` file:
```sql
<#assign
  conn = new_connection(
    "jdbc:oracle:thin:@//localhost:1521/orcl",
    "scott", "tiger"
  )
/>

<#assign
  partitions = conn.query(
    "select " +
      "t.region name, " +
      "listagg(t.shop_id, ', ') within group (order by t.shop_id) vals " +
    "from shops t " +
    "group by t.region " +
    "order by t.region"
  )
/>

create table orders (
  order_id integer not null primary key,
  customer_id integer not null,
  shop_id integer not null,
  order_date date not null,
  status varchar2(10) not null
)
partition by list(shop_id) (
<#list partitions.hash_rows as p>
  partition ${p.NAME} values (${p.VALS})<#if p_has_next>,</#if>
</#list>
)
/

comment on table orders is 'Orders partitioned by region.'
/

<#assign void = conn.close()/>
```

The table creation OS-shell script:
```
java -cp ../java/* ftldb.CommandLine orders.ftl 1> orders.sql
sqlplus scott/tiger@orcl @orders.sql
```

> **Notice**: Classpath may differ from the one specified above but must include
> `ftldb.jar`, `freemarker.jar` and the JDBC driver.

The result of all three executions is the `orders` table created and the
following script printed:
```sql
create table orders (
  order_id integer not null primary key,
  customer_id integer not null,
  shop_id integer not null,
  order_date date not null,
  status varchar2(10) not null
)
partition by list(shop_id) (
  partition east values (2, 3, 7),
  partition north values (1, 4, 6, 9),
  partition south values (5, 8, 12),
  partition west values (10, 11, 13)
)
/
comment on table orders is 'Orders partitioned by region.'
/
```

Compare these three solutions. As you may see, the two latter are much simpler
and more readable, since there is no quotation and concatenation in the `create
table` statement. The FTL template looks just as plain SQL code with few extra
tags and macros.

Pay attention to how naturally the `orders` table template is integrated into
the `generator` package body in the second example. And the package is still
valid despite containing non-PL/SQL code. The secret is in using PL/SQL
conditional compilation directives with the explicit *false* condition, which
makes the compiler ignore it and allows us store FTL templates inside program
units. This also allows us to develop code generation logic in IDEs using their
content/code assist features for the SQL and PL/SQL languages.

Of course, FTLDB is not a silver bullet. It's not an apt solution for fully
dynamic code generation, where a static part cannot be isolated easily. In such
cases pure PL/SQL or Java code might be more appropriate.

> **Summary**: If your code generation logic contains more static code rather
> than dynamic elements, such as loops, conditions and placeholders, and the
> result must be well-formatted and must look as human-written, try FTLDB. It
> suits for any kind of server- & client-side code generation and should work
> for you.


Security
--------

The FTLDB database user requires only several system privileges:

  * `CREATE SESSION`
  * `CREATE PROCEDURE`
  * `CREATE TYPE`
  * `CREATE TABLE`
  * `QUOTA` at least 50M on the default tablespace

All the objects in the FTLDB schema are created with the invoker-rights option,
and due to this, execution privileges on them are granted to `PUBLIC`, which is
quite secure.

FreeMarker requires the following permission:

  * [`java.lang.RuntimePermission "getClassLoader"`](http://docs.oracle.com/javase/8/docs/api/java/lang/RuntimePermission.html)

Both FTLDB schema and its users must be granted this permission. The Java API
reads:

> This would grant an attacker permission to get the class loader for a 
> particular class. This is dangerous because having access to a class's class
> loader allows the attacker to load other classes available to that class
> loader. The attacker would typically otherwise not have access to those
> classes.

Take into account the risks related to allowing this permission.


Installation
------------

Before installing FTLDB make sure that you have Oracle Client of same or higher
version as the database (it must include `sqlplus`, `loadjava`, JRE and the JDBC
driver). The TNS name of the target instance must be registered in your local
`tnsnames.ora`.

> **Notice**: Oracle Client version 11.2.0.1.0 for Windows has a buggy
> `loadjava` batch script. If the installation fails on the jar loading phase,
> upgrade the client to a higher version.

To install FTLDB download and unpack the release archive corresponding to your
OS. The archive includes:

  * `doc` directory
    * Java & PL/SQL API documentation
  * `ftl` directory
    * FTL macro libraries for basic needs
  * `java` directory
    * `freemarker.jar` - FreeMarker template engine
    * `ftldb.jar` - own classes for working with database connections, queries,
      callable statements and result sets in FTL (server-side & client-side)
  * `plsql` directory
    * types and packages providing API for using in PL/SQL
    * PL/SQL containers for the FTL macro libraries
  * `setup` directory
    * SQL*Plus scripts for creating objects and granting privileges
  * `*.bat` or `*.sh` scripts (depends on OS) - installers and deinstallers

#### DBA mode

If you have DBA access to the target database, use the `dba_install` script. It
must be run under any database superuser with the DBA privilege (e.g. `SYS` or
`SYSTEM`). It installs FTLDB as a standalone schema with the specified name and
password and grants it all the required privileges and permissions.

> **Warning**: If the specified schema already exists, it is dropped and
> recreated during the installation.

Run the DBA installation script from the base directory with the following five
parameters:

  1. target instance TNS name
  2. DBA user
  3. DBA password
  4. FTLDB schema name
  5. FTLDB password

> **Notice**: If the DBA password contains special characters, the installation
> may fail due to a peculiarity of `sqlplus`'s `connect` command implementation.

For example, on Windows you would run in the command line:

    dba_install.bat orcl sys manager ftldb ftldb

On Linux (or another *nix-like OS):

    ./dba_install.sh orcl sys manager ftldb ftldb

In order to grant other database users the required Java permissions run the
`dba_switch_java_permissions` script with the following parameters:

  1. target instance TNS name
  2. DBA user
  3. DBA password
  4. `grant` keyword (or `revoke` to revoke the permissions)
  5. list of grantee users separated by spaces

For example, on Windows you would run in the command line:

    dba_switch_java_permissions.bat orcl sys manager grant hr oe sh

On Linux (or another *nix-like OS):

    ./dba_switch_java_permissions.sh orcl sys manager grant hr oe sh

#### User mode

If you don't have full access to the target database, ask the DBA to create a
new schema with the required privileges and permissions (or use an existing
one).

The DBA may simply run the `setup/create_chema.sql` script to create the schema
and the `setup/dba_switch_java_permissions.sql` script to grant FTLDB and it
users the required permissions.

To install FTLDB as an ordinary user run the `usr_install` script with the
following three parameters:

  1. target instance TNS name
  2. FTLDB schema name
  3. FTLDB password

For example, on Windows you would run in the command line:

    usr_install.bat orcl ftldb ftldb

On Linux (or another *nix-like OS):

    ./usr_install.sh orcl ftldb ftldb

> **Notice**: It is not recommended to install FTLDB into a schema containing
> other objects. Instead, install it as a standalone schema and create local
> synonyms for the FTLDB objects.

---

You can change the default behavior and install FTLDB manually using scripts
from the `setup` directory.

In order to uninstall FTLDB run one of the `*_uninstall.*` scripts corresponding
to your OS and installation mode.


Demo
----

The demo archive contains the installer of another standalone schema, which
demonstrates the work of FTLDB with unit tests and several manual scripts.

The installer is itself an example of client-side FTLDB usage (it doesn't access
any database but demonstrates several script combining techniques). Check the
`*.ftl` files in the `setup` directory.

The tests are used for the CI purposes and can be useful as a source of
server-side usage examples. Check the `ut_ftldb_api$process.pks` file, which is
probably the most interesting for you.

The demo scripts are not installed automatically. You should run them manually
step by step. Explore the `demo` directory. Each demo contains its own `readme`
or `install.sql` file. Follow the instructions inside.

The installation process is very similar to the previous one. Run the main
installation script from the base directory with the following six parameters:

  1. target instance TNS name
  2. DBA user
  3. DBA password
  4. FTLDB schema name
  5. DEMO schema name
  6. DEMO password

It creates the demo schema and runs the tests. After the installation has
finished you can connect to the demo schema and run the demos manually.

> **Notice**: Make sure that the target instance has the same TNS name on the
> server and the client. Otherwise some unit tests won't pass.


Building the project
--------------------

In order to make a build by yourself you need an Oracle instance (optional),
[JDK 6](http://www.oracle.com/technetwork/java/javase/downloads/index.html) (or
higher) and [Maven 3](http://maven.apache.org/). The latest versions of both are
recommended.

Do the following:

  1. Download and unpack the source archive or clone from the GitHub repository.
  2. Open the `src/test/ftl/dbconn.config.ftl` file and set valid JDBC
     connection parameters for the client-side tests.
  3. Run in the command line from the base project directory:  
     `mvn clean package` or `mvn clean package -Dmaven.test.skip=true`  
     if you don't have an Oracle instance available.
  4. Check the `target` directory for the installation files.

> **Notice**: The client-side tests are also a good source of usage examples.


Authors
-------

The project is created and maintained by:

  * [Victor Osolovskiy](http://github.com/vosolovskiy)
  * [Sergey Navrotskiy](http://github.com/sns777)


License
-------

FTLDB is free software, licensed under the Apache License, Version 2.0. See
`LICENSE` and `NOTICE` files for more info.


Sponsors
--------

The first FTLDB prototype was written by the authors during their work at
[CUSTIS](http://custis.ru). Its infrastructure is still used for testing and
continuous integration.
