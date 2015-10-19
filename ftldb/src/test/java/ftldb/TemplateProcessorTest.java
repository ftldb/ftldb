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

import java.io.*;


public class TemplateProcessorTest {

    private static String process(String templName) throws Exception {
        Configurator.setConfiguration(new FileInputStream(new File("config/ftldb_config.xml")));
        StringWriter sw = new StringWriter();
        TemplateProcessor.process(templName, sw);
        String ret = sw.toString();
        System.out.println(ret);
        return ret;
    }

    private static String processBody(String templBody) throws Exception {
        Configurator.setConfiguration(new ftldb.DefaultConfiguration());
        Configurator.getConfiguration().setDefaultEncoding("UTF-8");
        StringWriter sw = new StringWriter();
        TemplateProcessor.process(new StringReader(templBody), sw);
        String ret = sw.toString();
        System.out.println(ret);
        return ret;
    }

    @Test
    public void testStatic() throws Exception {
        process("@ftldb/test_static.ftl");
    }

    @Test
    public void testTemplateLine() throws Exception {
        process("@ftldb/test_template_line.ftl");
    }

    @Test
    public void testSharedHash() throws Exception {
        CommandLine.main(new String[]{
                "@ftldb/test_shared_hash1.ftl", "x", "y", "z", "!", "@ftldb/test_shared_hash2.ftl"
        });
    }

    @Test
    public void testInclude() throws Exception {
        process("@ftldb/test_include.ftl");
    }

    @Test
    public void testText() throws Exception {
        processBody("<#assign X = 777/>\nX = ${X?c}");
    }

    @Test
    public void testNewConnection() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        process("@ftldb/test_new_connection.ftl");
    }

    @Test
    public void testDefaultConnection() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        process("@ftldb/test_default_connection.ftl");
    }

    @Test
    public void testQueryAndCallExecutors() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        process("@ftldb/test_query_and_call.ftl");
    }

    @Test
    public void testShellExec() throws Exception {
        process("@ftldb/test_shell_exec.ftl");
    }

}
