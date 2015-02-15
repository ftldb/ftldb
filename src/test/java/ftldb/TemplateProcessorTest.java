/*
 * Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package ftldb;


import org.junit.Test;

import java.io.StringReader;
import java.io.StringWriter;


public class TemplateProcessorTest {

    private static String process(String templName) throws Exception {
        Configurator.newConfiguration();
        Configurator.setDefaultFileTemplateLoader();
        Configurator.getConfiguration().setDefaultEncoding("UTF-8");
        StringWriter sw = new StringWriter();
        TemplateProcessor.process(templName, sw);
        String ret = sw.toString();
        System.out.println(ret);
        return ret;
    }

    private static String processBody(String templBody) throws Exception {
        Configurator.newConfiguration();
        Configurator.getConfiguration().setDefaultEncoding("UTF-8");
        StringWriter sw = new StringWriter();
        TemplateProcessor.processBody(new StringReader(templBody), sw);
        String ret = sw.toString();
        System.out.println(ret);
        return ret;
    }

    @Test
    public void testStatic() throws Exception {
        process("test_static.ftl");
    }

    @Test
    public void testTemplateLine() throws Exception {
        process("test_template_line.ftl");
    }

    @Test
    public void testGlobalContext() throws Exception {
        CommandLine.main(new String[]{
                "test_global_context1.ftl", "x", "y", "z", "!", "test_global_context2.ftl"
        });
    }

    @Test
    public void testInclude() throws Exception {
        process("test_include.ftl");
    }

    @Test
    public void testText() throws Exception {
        processBody("<#assign X = 777/>\nFirst call: X = ${X?c}");
        processBody("Second call: X = ${(X!-1)?c}");
    }

    @Test
    public void testNewDBConnection() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        process("test_new_connection.ftl");
    }

    @Test
    public void testDefaultDBConnection() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        process("test_default_connection.ftl");
    }

    @Test
    public void testDBQueryAndCallExecutors() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        process("test_query_and_exec.ftl");
    }

    @Test
    public void testDBQEColMetaData() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        process("test_colmetadata.ftl");
    }

    @Test
    public void testDBQECol() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        process("test_col_sets.ftl");
    }

}
