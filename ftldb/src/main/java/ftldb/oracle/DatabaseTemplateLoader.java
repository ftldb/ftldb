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
 * This class finds, checks and loads templates from an Oracle database executing registered
 * {@link CallableStatement}s. An instance is constructed with three specified functions:
 * <ul>
 *     <li>{@code templateFinderFunc} finds a template by its name and returns its string locator</li>
 *     <li>{@code templateLoaderFunc} loads the template's source from the database by its locator</li>
 *     <li>{@code templateCheckerFunc} checks the template's freshness by its locator (optional)</li>
 * </ul>
 *
 * <p>In the default implementation the following functions from the FTLDB_API package are used:
 * <pre>
 * {@code
 * function get_templ_locator_xmlstr(in_templ_name in varchar2) return varchar2;
 * function get_templ_body(in_locator_xmlstr in varchar2) return clob;
 * function get_templ_last_modified(in_locator_xmlstr in varchar2) return integer;
 * }
 * </pre>
 *
 * <p>Where locator is an XML encoded PL/SQL object instance of a TEMPL_LOCATOR_OT subtype.
 *
 * <p>If the checker function is not set, {@link #getLastModified} always returns {@code System.currentTimeMillis()}.
 *
 */
public class DatabaseTemplateLoader implements StatefulTemplateLoader {


    private final Connection connection;
    private final String templateFinderCall;
    private final String templateLoaderCall;
    private final String templateCheckerCall;
    private CallableStatement templateFinderCS;
    private CallableStatement templateLoaderCS;
    private CallableStatement templateCheckerCS;


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database.
     *
     * @param connection an opened connection to a database
     * @param templateFinderFunc a database function that finds a template by its name and returns its locator
     * @param templateLoaderFunc a database function that returns a template's source
     * @param templateCheckerFunc a database function that gets a template's timestamp - optional (nullable)
     */
    public DatabaseTemplateLoader(Connection connection, String templateFinderFunc, String templateLoaderFunc,
                                  String templateCheckerFunc ) {
        this.connection = connection;
        this.templateFinderCall = "{? = call " + templateFinderFunc + "(?)}";
        this.templateLoaderCall = "{? = call " + templateLoaderFunc + "(?)}";
        this.templateCheckerCall = (templateCheckerFunc == null || "".equals(templateCheckerFunc.trim()))
                                    ? null
                                    : "{? = call " + templateCheckerFunc + "(?)}";
    }


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database via the default driver's
     * connection.
     *
     * @param templateFinderFunc a database function that finds a template by its name and returns its locator
     * @param templateLoaderFunc a database function that returns a template's source
     * @param templateCheckerFunc a database function that gets a template's timestamp - optional (nullable)
     * @throws SQLException if a database access error occurs
     */
    public DatabaseTemplateLoader(String templateFinderFunc, String templateLoaderFunc, String templateCheckerFunc)
            throws SQLException {
        this(DriverManager.getConnection("jdbc:default:connection"),
                templateFinderFunc, templateLoaderFunc, templateCheckerFunc);
    }


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database via the default driver's
     * connection with disabled template timestamp checking.
     *
     * @param templateFinderFunc a database function that finds a template by its name and returns its locator
     * @param templateLoaderFunc a database function that returns a template's source
     * @throws SQLException if a database access error occurs
     */
    public DatabaseTemplateLoader(String templateFinderFunc, String templateLoaderFunc) throws SQLException {
        this(templateFinderFunc, templateLoaderFunc, null);
    }


    private CallableStatement getTemplateFinderCS() throws SQLException {
        if (templateFinderCS == null) {
            templateFinderCS = connection.prepareCall(templateFinderCall);
        }
        return templateFinderCS;
    }


    private CallableStatement getTemplateLoaderCS() throws SQLException {
        if (templateLoaderCS == null) {
            templateLoaderCS = connection.prepareCall(templateLoaderCall);
        }
        return templateLoaderCS;
    }


    private CallableStatement getTemplateCheckerCS() throws SQLException {
        if (templateCheckerCall == null) return null;

        if (templateCheckerCS == null) {
            templateCheckerCS = connection.prepareCall(templateCheckerCall);
        }
        return templateCheckerCS;
    }


    /**
     * Closes the inner {@link CallableStatement}s that are used for getting template sources.
     */
    public synchronized void resetState() {
        if (templateFinderCS != null) {
            try {
                templateFinderCS.close();
            } catch (SQLException ignored) {
            } finally {
                templateFinderCS = null;
            }
        }
        if (templateLoaderCS != null) {
            try {
                templateLoaderCS.close();
            } catch (SQLException ignored) {
            } finally {
                templateLoaderCS = null;
            }
        }
        if (templateCheckerCS != null) {
            try {
                templateCheckerCS.close();
            } catch (SQLException ignored) {
            } finally {
                templateCheckerCS = null;
            }
        }
    }


    /**
     * Executes the inner finder {@link CallableStatement} and gets the sought template's location.
     *
     * @param name the template's name
     * @return the template's locator
     * @throws IOException if a database access error occurs
     */
    public synchronized Object findTemplateSource(String name) throws IOException {
        try {
            CallableStatement tf = getTemplateFinderCS();
            tf.registerOutParameter(1, Types.VARCHAR); //locator as an XML string
            tf.setString(2, name);
            tf.execute();

            return tf.getString(1);
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to find template named " + name).initCause(e);
        }
    }


    /**
     * Executes the inner checker {@link CallableStatement} (if set) and gets the sought template's timestamp as a long
     * value. If the checker call is not set, returns current time.
     *
     * @param o the object storing the template's locator
     * @return the template's timestamp
     */
    public long getLastModified(Object o) {
        if (templateCheckerCall == null) return System.currentTimeMillis();

        String locator = (String) o;

        try {
            CallableStatement tc = getTemplateCheckerCS();
            tc.registerOutParameter(1, Types.BIGINT);
            tc.setString(2, locator);
            tc.execute();
            return tc.getLong(1);
        } catch (SQLException e) {
            throw new RuntimeException("Unable to check timestamp for template locator " + locator, e);
        }
    }


    /**
     * Executes the inner loader {@link CallableStatement} and gets the sought template's source.
     *
     * @param o the object storing the template's location description
     * @return the template source as a {@link Reader} stream
     * @throws IOException if a database access error occurs
     */
    public synchronized Reader getReader(Object o, String encoding) throws IOException {
        String locator = (String) o;

        try {
            CallableStatement tl = getTemplateLoaderCS();
            tl.registerOutParameter(1, Types.CLOB);
            tl.setString(2, locator);
            tl.execute();
            return tl.getClob(1).getCharacterStream();
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to load template from locator " + locator).initCause(e);
        }
    }


    /**
     * Actually does nothing.
     *
     * @param o the object storing the template's location description
     * @throws IOException never
     */
    public void closeTemplateSource(Object o) throws IOException { }


    private String formatCall(String call)  {
        if (call == null) return "null";

        String fc = call.replaceAll("\\s+", " ").trim();
        if (fc.length() > 100) fc = fc.substring(0, 100) + "...";
        return "\"" + fc + "\"";
    }


    /**
     * Returns the template loader name that is used in error log messages.
     *
     * @return the class name and the database calls
     */
    public String toString() {
        return this.getClass().getName() + "(templateFinderCall=" + formatCall(templateFinderCall) + "; "
                + "templateLoaderCall=" + formatCall(templateLoaderCall) + "; "
                + "templateCheckerCall=" + formatCall(templateCheckerCall) + ")";
    }


}
