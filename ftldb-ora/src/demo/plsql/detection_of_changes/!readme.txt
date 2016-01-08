====
    Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy

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

Demonstration of solving a real applied problem: detection of changes in a
remote source.

1. On the demo schema run `!install.sql`. It will install the base objects,
which are needed to simulate a real system, and the generator package.

2. Explore the `demo_dtoch_gen` package.

3. Use `generate.sql` to generate utility objects for detection of changes in
three source tables.

4. Explore the result of generation and compare the new objects with their
templates.

5. Run `populate_data.sql` to fill two source tables with data.

6. Run the tests from `test_scr.sql` to see how the solution works.

7. Run `clean_result_of_generation.sql` to remove the generated objects and
return to point 2.

8. Run `!uninstall.sql` to remove all the directly installed objects (not
generated) and return to point 1.
