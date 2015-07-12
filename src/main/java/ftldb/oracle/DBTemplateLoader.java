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
 * <ol>
 *     <li>{@code templateResolverCall} - this call resolves a template's name into a full DB object description</li>
 *     <li>{@code templateCheckerCall} - this call checks the template's freshness - not supported</li>
 *     <li>{@code templateLoaderCall} - this call loads the template's source from the database</li>
 * </ol>
 *
 * <p>By default the resolver call looks as:
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
 * <p>This class does not have a proper {@link StatefulTemplateLoader#getLastModified(Object)} implementation. So the
 * {@code templateCheckerCall} is ignored and the configuration must be set with no template caching.
 *
 * <p>By default the loader call looks as:
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
 * <p>The default calls may be redefined.
 */
public class DBTemplateLoader implements StatefulTemplateLoader {

    private Connection connection;
    private final String templateResolverCall;
    //private final String templateCheckerCall;
    private final String templateLoaderCall;
    private CallableStatement templateResolverCS;
    //private CallableStatement templateCheckerCS;
    private CallableStatement templateLoaderCS;


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database.
     *
     * @param conn an opened connection to a database
     * @param templateResolverCall a call to the database that resolves a template's name
     * @param templateCheckerCall a call to the database that gets a template's timestamp
     * @param templateLoaderCall a call to the database that returns a template's source
     */
    public DBTemplateLoader(
            Connection conn, String templateResolverCall, String templateCheckerCall, String templateLoaderCall
    ) {
        this.connection = conn;
        this.templateResolverCall = templateResolverCall;
        //this.templateCheckerCall = templateCheckerCall;
        this.templateLoaderCall = templateLoaderCall;
    }


    private CallableStatement getTemplateResolverCS() throws SQLException {
        if (templateResolverCS == null) {
            templateResolverCS = connection.prepareCall(templateResolverCall);
        }
        return templateResolverCS;
    }


    //private CallableStatement getTemplateCheckerCS() throws SQLException {
    //    if (templateCheckerCS == null) {
    //        templateCheckerCS = connection.prepareCall(templateCheckerCall);
    //    }
    //    return templateCheckerCS;
    //}


    private CallableStatement getTemplateLoaderCS() throws SQLException {
        if (templateLoaderCS == null) {
            templateLoaderCS = connection.prepareCall(templateLoaderCall);
        }
        return templateLoaderCS;
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
        //if (templateCheckerCS != null) {
        //    try {
        //        templateCheckerCS.close();
        //    } catch (SQLException e) {
        //    } finally {
        //        templateCheckerCS = null;
        //    }
        //}
        if (templateLoaderCS != null) {
            try {
                templateLoaderCS.close();
            } catch (SQLException e) {
            } finally {
                templateLoaderCS = null;
            }
        }
    }


    /**
     * Executes the inner resolver {@link CallableStatement} and gets the sought template's container description.
     *
     * @param name the template's name
     * @return the template's container description as an object
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

            return new DBTemplateContainer(name, owner, object, section, dblink, type);
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to find template named " + name)
                    .initCause(e);
        }
    }


    /**
     * Actually does nothing.
     *
     * @param o the object storing the template's container description
     * @return constant {@code -1L}
     */
    public long getLastModified(Object o) {
        return -1L;
    }


    /**
     * Executes the inner loader {@link CallableStatement} and gets the sought template's source.
     *
     * @param o the object storing the template's container description
     * @return the template source as a {@link Reader}
     * @throws IOException if a database access error occurs
     */
    public synchronized Reader getReader(Object o, String encoding) throws IOException {
        DBTemplateContainer templateContainer = (DBTemplateContainer) o;

        try {
            CallableStatement tl = getTemplateLoaderCS();
            tl.setString(1, templateContainer.owner);
            tl.setString(2, templateContainer.object);
            tl.setString(3, templateContainer.section);
            tl.setString(4, templateContainer.dblink);
            tl.setString(5, templateContainer.type);
            tl.registerOutParameter(6, Types.CLOB);
            tl.execute();
            return tl.getClob(6).getCharacterStream();
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to load template named " + templateContainer.name +
                    " from container " + templateContainer.getFullName()).initCause(e);
        }
    }


    /**
     * Actually does nothing.
     *
     * @param o the object storing the template's container description
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
        return this.getClass().getName() + "(templateResolverCall=" + formatCall(templateResolverCall) + "; " +
                "templateLoaderCall=" + formatCall(templateLoaderCall) + ")";
    }


    /**
     * This class represents a template's container description.
     */
    public static class DBTemplateContainer {
        final String name;

        final String owner;
        final String object;
        final String section;
        final String dblink;
        final String type;

        DBTemplateContainer(String name, String owner, String object, String section, String dblink, String type) {
            this.name = name;
            this.owner = owner;
            this.object = object;
            this.section = (section == null) ? "" : section.toUpperCase();
            this.dblink = (dblink == null) ? "" : dblink.toUpperCase();
            this.type = type.toUpperCase();
        }

        String getFullName() {
            return ((owner.toUpperCase().equals(owner)) ? owner : "\"" + owner + "\"") + "." +
                    ((object.toUpperCase().equals(object)) ? object : "\"" + object + "\"") +
                    ((section.length() > 0) ? '%' + section : "") +
                    ((dblink.length() > 0) ? '@' + dblink : "") +
                    " (" + type + ")";
        }

        public boolean equals(Object o) {
            if (this == o)
                return true;
            if (o == null)
                return false;
            if (this.getClass() != o.getClass())
                return false;

            DBTemplateContainer other = (DBTemplateContainer) o;
            return this.owner.equals(other.owner) && this.object.equals(other.object) &&
                    this.section.equals(other.section) && this.dblink.equals(other.dblink) &&
                    this.type.equals(other.type);
        }

        public int hashCode() {
            final int prime = 31;
            int result = 1;
            result = prime * result + owner.hashCode();
            result = prime * result + object.hashCode();
            result = prime * result + section.hashCode();
            result = prime * result + dblink.hashCode();
            result = prime * result + type.hashCode();
            return result;
        }

    }

}
