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

import freemarker.template.SimpleScalar;
import freemarker.template.SimpleSequence;
import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModelException;

import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * This class is a shell command executor.
 */
public class ShellCommandExecutor {

    /**
     * Implements a {@link TemplateMethodModelEx} FTL method interface. Creates a method named {@code shell_exec},
     * which 1st argument - the command - is mandatory, and the 2nd argument - the output encoding - is optional.
     * The command may be passed either as a whole string ("ls -l") or as an array (["ls", "-l"]). The default encoding
     * is UTF-8.
     *
     * @return an FTL method for executing a shell command
     */
    public static TemplateMethodModelEx getMethodShellExecute() {
        return new TemplateMethodModelEx() {
            public Object exec(List args) throws TemplateModelException {

                if (args.size() < 1) throw new TemplateModelException("At least one argument expected, got 0");

                String[] cmdArray;

                if (args.get(0) instanceof SimpleScalar) {
                    cmdArray = new String[]{((SimpleScalar) args.get(0)).getAsString()};
                } else if (args.get(0) instanceof SimpleSequence) {
                    try {
                        List cmdList = ((SimpleSequence) args.get(0)).toList();
                        cmdArray = (String[]) cmdList.toArray(new String[cmdList.size()]);
                    } catch (RuntimeException e) {
                        throw new TemplateModelException("Illegal type of elements of argument #0", e);
                    }
                } else {
                    throw new TemplateModelException("Illegal type of argument #0: "
                            + "expected SimpleScalar or SimpleSequence, got " + args.get(0).getClass().getName()
                    );
                }

                String encoding;

                if (args.size() < 2) {
                    encoding = "UTF-8";
                } else {
                    if (args.get(1) instanceof SimpleScalar) {
                        encoding = ((SimpleScalar) args.get(1)).getAsString();
                    } else {
                        throw new TemplateModelException("Illegal type of argument #0: "
                                + "expected SimpleScalar, got " + args.get(0).getClass().getName()
                        );
                    }
                }

                try {
                    return ShellCommandExecutor.executeCommand(cmdArray, encoding);
                } catch (Exception e) {
                    throw new TemplateModelException("Shell command execution failed", e);
                }

            }
        };
    }


    public static Map executeCommand(String[] cmdArray, String encoding) throws Exception {

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


