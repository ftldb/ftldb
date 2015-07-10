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


import freemarker.cache.StatefulTemplateLoader;

import java.io.IOException;
import java.io.Reader;
import java.sql.*;


/**
 * This class loads templates from an Oracle database executing a registered {@link CallableStatement}. An instance is
 * constructed with the specified call to a function, which has two bind variables: the first (out) returns the body of
 * the found template as a {@link Clob} and the second (in) takes the name of a template.
 *
 * <p>By default, the call looks as:
 * <pre>
 * {@code
 * {? = call ftldb_api.default_template_loader(?)}
 * }
 * </pre>
 *
 * <p>where the specification of the {@code default_template_loader} function in the {@code ftldb_api} package is:
 * <pre>
 * {@code
 * function default_template_loader(in_templ_name in varchar2) return clob;
 * }
 * </pre>
 *
 * <p>but the default loader may be redefined with another function.
 *
 * <p>This class does not have a proper {@link StatefulTemplateLoader#getLastModified(Object)} implementation. So the
 * configuration must be set with no template caching.
 */
public class DBTemplateLoader implements StatefulTemplateLoader {

    private Connection connection;
    private final String templateLoaderCall;
    private CallableStatement templateFactory;


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database.
     *
     * @param connection an opened connection to a database
     * @param templateLoaderCall a proper call that can be performed in that database
     */
    public DBTemplateLoader(Connection connection, String templateLoaderCall) {
        this.connection = connection;
        this.templateLoaderCall = templateLoaderCall;
    }


    private CallableStatement getCall() throws SQLException {
        if (templateFactory == null) {
            templateFactory = connection.prepareCall(templateLoaderCall);
        }
        return templateFactory;
    }


    /**
     * Closes the inner {@link CallableStatement} that is used for getting template sources.
     */
    public synchronized void resetState() {
        if (templateFactory != null) {
            try {
                templateFactory.close();
            } catch (SQLException e) {
            } finally {
                templateFactory = null;
            }
        }
    }


    /**
     * Executes the inner {@link CallableStatement} and gets the sought template source.
     *
     * @param name the template name
     * @return the template source
     * @throws IOException if a database access error occurs
     */
    public synchronized Object findTemplateSource(String name) throws IOException {
        try {
            CallableStatement tf = getCall();
            tf.registerOutParameter(1, Types.CLOB);
            tf.setString(2, name);
            tf.execute();
            return tf.getClob(1);
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to find template named " + name).initCause(e);

        }
    }


    /**
     * Actually does nothing.
     *
     * @param o the object storing the template source as a {@link Clob}
     * @return constant {@code -1L}
     */
    public long getLastModified(Object o) {
        return -1L;
    }


    /**
     * Represents the extracted template source as a character stream.
     *
     * @param o the object storing the template source as a {@link Clob}
     * @return the template source as a {@link Reader}
     * @throws IOException if a database access error occurs
     */
    public synchronized Reader getReader(Object o, String encoding) throws IOException {
        try {
            return ((Clob) o).getCharacterStream();
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to read loaded template").initCause(e);
        }
    }


    /**
     * Actually does nothing.
     *
     * @param o the object storing the template source as a {@link Clob}
     * @throws IOException never
     */
    public void closeTemplateSource(Object o) throws IOException { }


    /**
     * Returns the template loader name that is used in error log messages.
     *
     * @return the class name and the database call
     */
    public String toString() {
        String tlc = templateLoaderCall.replaceAll("\\s+", " ").trim();
        if (tlc.length() > 100) tlc = tlc.substring(0, 100) + "...";
        return this.getClass().getName() + "(templateLoaderCall=\"" + tlc + "\")";
    }

}
