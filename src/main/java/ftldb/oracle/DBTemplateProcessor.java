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
package ftldb.oracle;


import ftldb.Configurator;
import ftldb.TemplateProcessor;

import java.io.Writer;
import java.sql.Array;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;


/**
 * This class implements the functionality of {@link TemplateProcessor} for working in Oracle Database server-side.
 */
public class DBTemplateProcessor {

    /**
     * Processes a template with the specified name.
     *
     * <p>This method is a part of FTLDB API for PL/SQL.
     *
     * @param templateName the template name
     * @return the processed template body
     * @throws Exception if a template processing or database access error occurs
     */
    public static Clob process(String templateName) throws Exception {
        Connection connection = DriverManager.getConnection("jdbc:default:connection");
        Clob ret = oracle.sql.CLOB.createTemporary(connection, true, oracle.sql.CLOB.DURATION_SESSION);
        Writer w = ret.setCharacterStream(0);
        TemplateProcessor.process(templateName, w);
        w.close();
        return ret;
    }


    /**
     * Processes the specified template body.
     *
     * <p>This method is a part of FTLDB API for PL/SQL.
     *
     * @param templateBody the template body
     * @return the processed template body
     * @throws Exception if a template processing or database access error occurs
     */
    public static Clob processBody(Clob templateBody) throws Exception {
        Connection connection = DriverManager.getConnection("jdbc:default:connection");
        Clob ret = oracle.sql.CLOB.createTemporary(connection, true, oracle.sql.CLOB.DURATION_SESSION);
        Writer w = ret.setCharacterStream(0);
        TemplateProcessor.processBody(templateBody.getCharacterStream(), w);
        w.close();
        return ret;
    }


    /**
     * Adds the specified SQL collection to the configuration as a sequence named {@code template_args}.
     *
     * <p>This method is a part of FTLDB API for PL/SQL.
     *
     * @param templateArgs the collection of template arguments
     * @throws Exception if a configuration or database access error occurs
     */
    public static void setArguments(Array templateArgs) throws Exception {
        Configurator.getConfiguration().setSharedVariable("template_args", (String[]) templateArgs.getArray());
    }

}
