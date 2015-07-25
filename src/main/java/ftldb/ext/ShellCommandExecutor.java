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
package ftldb.ext;


import freemarker.template.SimpleScalar;
import freemarker.template.SimpleSequence;
import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModelException;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


/**
 * This class is a shell command executor. It contains private methods for executing shell commands and a public static
 * class for FTL.
 */
public class ShellCommandExecutor {


    /**
     * This class implements an FTL method named {@code shell_exec} that executes the given shell command and returns
     * the result fetched from the standard system output streams. Returns a map with two keys: "stdout" and "stderr",
     * each containing corresponding output stream as an array of lines. The default encoding is UTF8.
     *
     * <p>Method definition: {@code Map<String, String[]> shell_exec(String command)}
     * <p>Method arguments:
     * <pre>
     *     {@code command} - the command to be executed
     * </pre>
     *
     * <p>Method overloading: {@code Map<String, String[]> shell_exec(String command, String encoding)}
     * <p>Method arguments:
     * <pre>
     *     {@code command} - the command to be executed
     *     {@code encoding} - the encoding of standard system streams
     * </pre>
     *
     * <p>Method overloading: {@code Map<String, String[]> shell_exec(String[] command_array)}
     * <p>Method arguments:
     * <pre>
     *     {@code command_array} - the command to be executed passed as an array
     * </pre>
     *
     * <p>Method overloading: {@code Map<String, String[]> shell_exec(String[] command_array, String encoding)}
     * <p>Method arguments:
     * <pre>
     *     {@code command_array} - the command to be executed passed as an array
     *     {@code encoding} - the encoding of standard system streams
     * </pre>
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * <#assign lines = shell_exec("ls -1").stdout/>
     * <#list lines as line>
     * ${line}
     * </#list>
     *
     * <#assign lines = shell_exec(["cmd", "/c", "dir", "/b"], "Cp1252").stdout/>
     * <#list lines as line>
     * ${line}
     * </#list>
     *
     * <#assign lines = shell_exec("java -version").stderr/>
     * <#list lines as line>
     * ${line}
     * </#list>
     * }
     * </pre>
     */
    public static class ShellExecMethod implements TemplateMethodModelEx {

        public Object exec(List args) throws TemplateModelException {

            if (args.size() < 1) {
                throw new TemplateModelException("At least one argument expected, got 0");
            }

            String[] cmdArray;

            if (args.get(0) instanceof SimpleScalar) {
                cmdArray = new String[]{((SimpleScalar) args.get(0)).getAsString()};
            } else if (args.get(0) instanceof SimpleSequence) {
                try {
                    List cmdList = ((SimpleSequence) args.get(0)).toList();
                    cmdArray = (String[]) cmdList.toArray(new String[cmdList.size()]);
                } catch (RuntimeException e) {
                    throw new TemplateModelException("Illegal type of elements of sequence argument #1", e);
                }
            } else {
                throw new TemplateModelException("Illegal type of argument #1: "
                        + "expected SimpleScalar or SimpleSequence, got " + args.get(0).getClass().getName());
            }

            String encoding;

            if (args.size() < 2) {
                encoding = "UTF8";
            } else {
                if (args.get(1) instanceof SimpleScalar) {
                    encoding = ((SimpleScalar) args.get(1)).getAsString();
                } else {
                    throw new TemplateModelException("Illegal type of argument #2: "
                            + "expected SimpleScalar, got " + args.get(0).getClass().getName());
                }
            }

            try {
                return executeCommand(cmdArray, encoding);
            } catch (Exception e) {
                throw new TemplateModelException("Shell command execution failed", e);
            }

        }

    }


    private static Map executeCommand(String[] cmdArray, String encoding) throws Exception {

        Process p;
        Map result = new HashMap(2, 1);

        p = (cmdArray.length == 1)
                ? Runtime.getRuntime().exec(cmdArray[0])
                : Runtime.getRuntime().exec(cmdArray);
        p.waitFor();
        result.put("stdout", readStandardStream(p.getInputStream(), encoding));
        result.put("stderr", readStandardStream(p.getErrorStream(), encoding));

        return result;

    }


    private static String[] readStandardStream(InputStream stream, String encoding) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(stream, encoding));

        List lines = new ArrayList(16);
        String line;

        try {
            while ((line = reader.readLine()) != null) {
                lines.add(line);
            }
        } catch (IOException e) {
            try {
                reader.close();
            } catch (IOException e2) {
                throw (IOException) e2.initCause(e);
            }
            throw e;
        }
        reader.close();

        return (String[]) lines.toArray(new String[lines.size()]);
    }


}


