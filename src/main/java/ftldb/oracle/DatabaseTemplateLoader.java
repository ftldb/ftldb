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
 * This class resolves, checks and loads templates from an Oracle database executing registered
 * {@link CallableStatement}s. An instance is constructed with three specified calls:
 * <ul>
 *     <li>{@code templateResolverCall} resolves a template's name into a full DB object description</li>
 *     <li>{@code templateLoaderCall} loads the template's source from the database</li>
 *     <li>{@code templateCheckerCall} checks the template's freshness - optional</li>
 * </ul>
 *
 * <p>The resolver call looks as:
 * <pre>
 * {@code
 * {call ftldb_api.default_template_resolver(?, ?, ?, ?, ?, ?)}
 * }
 * </pre>
 *
 * <p>where the specification of the {@code default_template_resolver} procedure in the {@code ftldb_api} package is:
 * <pre>
 * {@code
 * procedure default_template_resolver(
 *   in_templ_name in varchar2,
 *   out_owner out varchar2,
 *   out_name out varchar2,
 *   out_sec_name out varchar2,
 *   out_dblink out varchar2,
 *   out_type out varchar2
 * );
 * }
 * </pre>
 *
 * <p>The loader call looks as:
 * <pre>
 * {@code
 * {call ftldb_api.default_template_loader(?, ?, ?, ?, ?, ?)}
 * }
 * </pre>
 *
 * <p>where the specification of the {@code default_template_loader} procedure in the {@code ftldb_api} package is:
 * <pre>
 * {@code
 * procedure default_template_loader(
 *   in_owner in varchar2,
 *   in_name in varchar2,
 *   in_sec_name in varchar2,
 *   in_dblink in varchar2,
 *   in_type in varchar2,
 *   out_body out clob
 * );
 * }
 * </pre>
 *
 * <p>The checker call looks as:
 * <pre>
 * {@code
 * {call ftldb_api.default_template_checker(?, ?, ?, ?, ?, ?)}
 * }
 * </pre>
 *
 * <p>where the specification of the {@code default_template_checker} procedure in the {@code ftldb_api} package is:
 * <pre>
 * {@code
 * procedure default_template_checker(
 *   in_owner in varchar2,
 *   in_name in varchar2,
 *   in_sec_name in varchar2,
 *   in_dblink in varchar2,
 *   in_type in varchar2,
 *   out_timestamp out integer
 * );
 * }
 * </pre>
 *
 * <p>If the checker call is not set, {@link #getLastModified} always returns {@code System.currentTimeMillis()}.
 *
 */
public class DatabaseTemplateLoader implements StatefulTemplateLoader {


    private Connection connection;
    private final String templateResolverCall;
    private final String templateLoaderCall;
    private final String templateCheckerCall;
    private CallableStatement templateResolverCS;
    private CallableStatement templateLoaderCS;
    private CallableStatement templateCheckerCS;


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database.
     *
     * @param connection an opened connection to a database
     * @param templateResolverCall a call to the database that resolves a template's name
     * @param templateLoaderCall a call to the database that returns a template's source
     * @param templateCheckerCall a call to the database that gets a template's timestamp - optional (nullable)
     */
    public DatabaseTemplateLoader(Connection connection, String templateResolverCall, String templateLoaderCall,
                                  String templateCheckerCall ) {
        this.connection = connection;
        this.templateResolverCall = templateResolverCall;
        this.templateLoaderCall = templateLoaderCall;
        this.templateCheckerCall = (templateCheckerCall == null || "".equals(templateCheckerCall.trim()))
                                    ? null
                                    : templateCheckerCall;
    }


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database via the default driver's
     * connection.
     *
     * @param templateResolverCall a call to the database that resolves a template's name
     * @param templateLoaderCall a call to the database that returns a template's source
     * @param templateCheckerCall a call to the database that gets a template's timestamp - optional (nullable)
     */
    public DatabaseTemplateLoader(String templateResolverCall, String templateLoaderCall, String templateCheckerCall)
            throws SQLException {
        this(DriverManager.getConnection("jdbc:default:connection"),
                templateResolverCall, templateLoaderCall, templateCheckerCall);
    }


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database via the default driver's
     * connection with disabled template timestamp checking.
     *
     * @param templateResolverCall a call to the database that resolves a template's name
     * @param templateLoaderCall a call to the database that returns a template's source
     */
    public DatabaseTemplateLoader(String templateResolverCall, String templateLoaderCall) throws SQLException {
        this(templateResolverCall, templateLoaderCall, null);
    }


    private CallableStatement getTemplateResolverCS() throws SQLException {
        if (templateResolverCS == null) {
            templateResolverCS = connection.prepareCall(templateResolverCall);
        }
        return templateResolverCS;
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
        if (templateResolverCS != null) {
            try {
                templateResolverCS.close();
            } catch (SQLException e) {
            } finally {
                templateResolverCS = null;
            }
        }
        if (templateLoaderCS != null) {
            try {
                templateLoaderCS.close();
            } catch (SQLException e) {
            } finally {
                templateLoaderCS = null;
            }
        }
        if (templateCheckerCS != null) {
            try {
                templateCheckerCS.close();
            } catch (SQLException e) {
            } finally {
                templateCheckerCS = null;
            }
        }
    }


    /**
     * Executes the inner resolver {@link CallableStatement} and gets the sought template's location.
     *
     * @param name the template's name
     * @return the template's location description
     * @throws IOException if a database access error occurs
     */
    public synchronized Object findTemplateSource(String name) throws IOException {
        try {
            CallableStatement tr = getTemplateResolverCS();
            tr.setString(1, name);
            tr.registerOutParameter(2, Types.VARCHAR); //owner
            tr.registerOutParameter(3, Types.VARCHAR); //object
            tr.registerOutParameter(4, Types.VARCHAR); //section
            tr.registerOutParameter(5, Types.VARCHAR); //dblink
            tr.registerOutParameter(6, Types.VARCHAR); //type
            tr.execute();

            String owner = tr.getString(2);
            String object = tr.getString(3);
            String section = tr.getString(4);
            String dblink = tr.getString(5);
            String type = tr.getString(6);

            // If name is not resolved
            if (owner == null || object == null || type == null) return null;

            return new TemplateLocator(name, owner, object, section, dblink, type);
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to find template named " + name).initCause(e);
        }
    }


    /**
     * Executes the inner checker {@link CallableStatement} (if set) and gets the sought template's timestamp as a long
     * value. If the checker call is not set, returns current time.
     *
     * @param o the object storing the template's location description
     * @return the template's timestamp
     */
    public long getLastModified(Object o) {
        if (templateCheckerCall == null) return System.currentTimeMillis();

        TemplateLocator t = (TemplateLocator) o;

        try {
            CallableStatement tc = getTemplateCheckerCS();
            tc.setString(1, t.owner);
            tc.setString(2, t.object);
            tc.setString(3, t.section);
            tc.setString(4, t.dblink);
            tc.setString(5, t.type);
            tc.registerOutParameter(6, Types.BIGINT);
            tc.execute();
            return tc.getLong(6);
        } catch (SQLException e) {
            throw new RuntimeException("Unable to check timestamp for template container "
                    + t.getFullNameWithType(), e);
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
        TemplateLocator t = (TemplateLocator) o;

        try {
            CallableStatement tl = getTemplateLoaderCS();
            tl.setString(1, t.owner);
            tl.setString(2, t.object);
            tl.setString(3, t.section);
            tl.setString(4, t.dblink);
            tl.setString(5, t.type);
            tl.registerOutParameter(6, Types.CLOB);
            tl.execute();
            return tl.getClob(6).getCharacterStream();
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to load template from " + t.getFullNameWithType()).initCause(e);
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
        return this.getClass().getName() + "(templateResolverCall=" + formatCall(templateResolverCall) + "; "
                + "templateLoaderCall=" + formatCall(templateLoaderCall) + "; "
                + "templateCheckerCall=" + formatCall(templateCheckerCall) + ")";
    }


    /**
     * This class represents a template's container description.
     */
    public static final class TemplateLocator {
        final String name;

        final String owner;
        final String object;
        final String section;
        final String dblink;
        final String type;

        TemplateLocator(String name, String owner, String object, String section, String dblink, String type) {
            this.name = name;
            this.owner = owner;
            this.object = object;
            this.section = (section == null) ? "" : section.toUpperCase();
            this.dblink = (dblink == null) ? "" : dblink.toUpperCase();
            this.type = type.toUpperCase();
        }

        String getFullName() {
            return ((owner.toUpperCase().equals(owner)) ? owner : "\"" + owner + "\"") + "."
                    + ((object.toUpperCase().equals(object)) ? object : "\"" + object + "\"")
                    + ((section.length() > 0) ? '%' + section : "")
                    + ((dblink.length() > 0) ? '@' + dblink : "")
                    + " (" + type + ")";
        }

        String getFullNameWithType() {
            return getFullName() + " (" + type + ")";
        }


        public boolean equals(Object o) {
            if (this == o)
                return true;
            if (!(o instanceof TemplateLocator))
                return false;

            TemplateLocator other = (TemplateLocator) o;
            return owner.equals(other.owner) && object.equals(other.object) && section.equals(other.section) &&
                    dblink.equals(other.dblink) && type.equals(other.type);
        }

        public int hashCode() {
            return owner.hashCode() ^ object.hashCode() ^ section.hashCode() ^ dblink.hashCode() ^ type.hashCode();
        }

    }

}
