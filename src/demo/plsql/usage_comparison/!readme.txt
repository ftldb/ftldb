====
    Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
====

Demo from the main README.

1. Connect to the demo schema and run `install.sql` from the current directory.

2. Explore the results of execution.

3. Copy the Oracle JDBC driver to the `java` directory (or set proper
classpath), edit the `orders.ftl` file (set database connection properties) and
run in the command line:

    java -cp ../../java/* ftldb.CommandLine orders.ftl 1> orders.sql

4. See the `orders.sql` file.
