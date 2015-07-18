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


import freemarker.template.Template;
import freemarker.template.TemplateException;
import freemarker.template.TemplateModelException;

import java.io.IOException;
import java.io.Writer;
import java.sql.Array;
import java.sql.Clob;
import java.sql.SQLException;


/**
 * Extension of {@link ftldb.TemplateProcessor} for working with templates in Oracle Database via JDBC interfaces,
 * which can be directly mapped to PL/SQL types.
 *
 * <p>Important: Oracle {@code in out} parameters are mapped to 1-element arrays of corresponding Java type.
 */
public class TemplateProcessor extends ftldb.TemplateProcessor {


    /**
     * Processes a template specified by its name.
     *
     * @param templateName the template's name
     * @param dest the output destination - a 1-element array mapped to PL/SQL in out CLOB parameter
     * @throws SQLException if a database access error occurs
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    public static void process(String templateName, Clob[] dest) throws SQLException, IOException, TemplateException {
        process(templateName, dest[0]);
    }


    /**
     * Processes a template represented as a {@link Clob} instance.
     *
     * @param templateBody the template's source
     * @param dest the output destination - a 1-element array mapped to PL/SQL in out CLOB parameter
     * @throws SQLException if a database access error occurs
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    public static void process(Clob templateBody, Clob[] dest) throws SQLException, IOException, TemplateException {
        process(templateBody, dest[0]);
    }


    /**
     * Adds the specified SQL array to the current configuration as a sequence named {@code template_args}.
     *
     * @param templateArgs a collection of string template arguments
     * @throws SQLException if a database access error occurs
     * @throws TemplateModelException if a configuration error occurs
     */
    public static void setArguments(Array templateArgs) throws SQLException, TemplateModelException {
        setArguments((String[]) templateArgs.getArray());
    }


    private static void process(Template template, Clob dest) throws SQLException, IOException, TemplateException {
        Writer w = dest.setCharacterStream(0);
        process(template, w);
        w.close();
    }


    private static void process(String templateName, Clob dest) throws SQLException, IOException, TemplateException {
        process(getTemplate(templateName), dest);
    }


    private static void process(Clob templateBody, Clob dest) throws SQLException, IOException, TemplateException {
        process(getTemplate(templateBody.getCharacterStream()), dest);
    }


}
