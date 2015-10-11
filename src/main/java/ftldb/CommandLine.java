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


import freemarker.cache.ClassTemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.TemplateException;

import java.io.*;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;


/**
 * This class provides a command line launcher for the FreeMarker engine with the support of the FTLDB functionality.
 * The result of processing FTL templates is directed to {@link System#out}.
 */
public class CommandLine {


    /**
     * The main entry point. Processes each listed template in left-to-right order, passing its arguments as a sequence
     * named {@code template_args}. Templates (with their arguments) are delimited by a '!' sign.
     *
     * @param args the full list of arguments
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    public static void main(String[] args) throws IOException, TemplateException {

        if (args.length < 1) {
            exitWithUsageExample("FTLDB v" + Configurator.getVersion() + ","
                    + " based on FreeMarker v" + Configurator.getFreeMarkerVersion() + ".");
        }

        Configuration cfg;
        int skip = 0;

        if (args.length > 0 && args[0].equals("-c")) {
            if (args.length < 2) {
                exitWithUsageExample("Config XML file name is missing!");
            }
            cfg = Configurator.newConfiguration(new FileInputStream(new File(args[1])));
            skip += 2;
        } else {
            cfg = new DefaultConfiguration();
            cfg.setTemplateLoader(new ResourceTemplateLoader());
        }

        List calls = getFtlCalls(args, skip);
        if (calls.size() == 0) {
            exitWithUsageExample("List of FTL files is missing!");
        }

        Configurator.setConfiguration(cfg);
        Writer out = new OutputStreamWriter(System.out);

        for (Iterator cmdIt = calls.iterator(); cmdIt.hasNext(); ) {
            List call = (List) cmdIt.next();
            if (call.size() == 0) continue;

            String templateName = (String) call.get(0);
            if ("".equals(templateName.trim())) {
                throw new RuntimeException("Empty template file name in call: " + call);
            }

            String[] templateArgs = (String[]) call.subList(1, call.size()).toArray(new String[call.size() - 1]);

            TemplateProcessor.setArguments(templateArgs);
            TemplateProcessor.process(templateName, out);
        }

    }


    private static final String FTL_CALL_DELIM = "!";


    private static List getFtlCalls(String[] args, int skip) {
        List ret = new ArrayList();

        int currCmdInd = 0;
        List currCmd = null;

        for (int i = skip; i < args.length; i++) {
            if (ret.size() == currCmdInd) {
                ret.add(currCmd = new ArrayList(8));
            }
            if (FTL_CALL_DELIM.equals(args[i])) {
                currCmdInd++;
            } else {
                currCmd.add(args[i]);
            }
        }
        return ret;
    }


    private static void exitWithUsageExample(String msg) {
        if (!(msg == null || "".equals(msg.trim()))) {
            System.err.println(msg);
        }
        System.err.println("Usage: java " + CommandLine.class.getName()
                            + " [-c configXmlFile]"
                            + " @ftlFile1 arg1 ... argN [" + FTL_CALL_DELIM
                            + " @ftlFile2 arg1 ... argN [" + FTL_CALL_DELIM
                            + " @ftlFileN ...]]");
        System.exit(1);
    }


}
