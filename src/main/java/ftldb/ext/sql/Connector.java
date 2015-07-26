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
package ftldb.ext.sql;


import freemarker.ext.beans.StringModel;
import freemarker.template.SimpleScalar;
import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModelException;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;


/**
 * This class is manages JDBC connections for FTL. It contains private methods for constructing
 * {@link ConnectionAdapter}s and public static classes for FTL.
 */
public class Connector {


    // The default connection set for the configuration.
    private static ConnectionAdapter defaultConnection;


    private static ConnectionAdapter newConnection() throws TemplateModelException {
        try {
            return new ConnectionAdapter(DriverManager.getConnection("jdbc:default:connection"));
        } catch (SQLException e) {
            throw new TemplateModelException(e);
        }
    }


    private static ConnectionAdapter newConnection(String url, String user, String password)
            throws TemplateModelException {
        try {
            return new ConnectionAdapter(DriverManager.getConnection(url, user, password));
        } catch (SQLException e) {
            throw new TemplateModelException(e);
        }
    }


    private static synchronized ConnectionAdapter getDefaultConnection() throws TemplateModelException {
        if (defaultConnection == null) {
            defaultConnection = newConnection();
        }
        return defaultConnection;
    }


    private static synchronized void setDefaultConnection(ConnectionAdapter connection) {
        defaultConnection = connection;
    }


    /**
     * This class implements an FTL method named {@code new_connection} that gets a new {@link java.sql.Connection} from
     * the {@link DriverManager} and wraps it into a {@link ConnectionAdapter}.
     *
     * <p>Method definition: {@code ConnectionAdapter new_connection(String url, String user, String password)}
     * <p>Method arguments:
     * <pre>
     *     {@code url} - a database url of the form <code>jdbc:<em>subprotocol</em>:<em>subname</em></code>
     *     {@code user} - the database user on whose behalf the connection is being made
     *     {@code password} - the user's password
     * </pre>
     *
     * <p>Method overloading: {@code ConnectionAdapter new_connection()}. Returns the driver's default connection with
     * the {@code "jdbc:default:connection"} url.
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * <#assign inner_conn = new_connection()/>
     * <#assign ext_conn = new_connection("jdbc:oracle:thin@//localhost:1521/orcl", "scott", "tiger")/>
     * }
     * </pre>
     */
    public static class NewConnectionMethod implements TemplateMethodModelEx {

        public Object exec(List args) throws TemplateModelException {

            if (args.size() == 0) {
                return newConnection();
            }

            if (args.size() != 3) {
                throw new TemplateModelException("Wrong number of arguments: expected 0 or 3, got " + args.size());
            }

            String[] strArgs = new String[3];
            for (int i = 0; i < 3; i++) {
                Object o = args.get(i);
                if (o instanceof SimpleScalar) {
                    strArgs[i] = ((SimpleScalar) o).getAsString();
                } else {
                    throw new TemplateModelException("Illegal type of argument #" + (i + 1) + ": "
                            + "expected SimpleScalar (i.e. String), got " + args.get(i).getClass().getName());
                }
            }

            String url = strArgs[0];
            String user = strArgs[1];
            String password = strArgs[2];

            return newConnection(url, user, password);
        }

    }


    /**
     * This class implements an FTL method named {@code default_connection} that gets the default {@link
     * ConnectionAdapter} set for the configuration. If the default connection have not been set, returns {@code
     * new_connection()}.
     *
     * <p>Method definition: {@code ConnectionAdapter default_connection()}
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * <#assign def_conn = default_connection()/>
     * }
     * </pre>
     */
    public static class GetDefaultConnectionMethod implements TemplateMethodModelEx {

        public Object exec(List args) throws TemplateModelException {
            if (args.size() != 0) {
                throw new TemplateModelException("Wrong number of arguments: expected 0, got " + args.size());
            }

            return getDefaultConnection();
        }

    }


    /**
     * This class implements an FTL method named {@code set_default_connection} that sets the default {@link
     * ConnectionAdapter} instance for the configuration.
     *
     * <p>Method definition: {@code void set_default_connection(ConnectionAdapter conn)}
     * <p>Method arguments:
     * <pre>
     *     {@code conn} - the new default connection
     * </pre>
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * <#assign ext_conn = new_connection("jdbc:oracle:thin@//localhost:1521/orcl", "scott", "tiger")/>
     * <#assign void = set_default_connection(ext_conn)/>
     * }
     * </pre>
     */
    public static class SetDefaultConnectionMethod implements TemplateMethodModelEx {

        public Object exec(List args) throws TemplateModelException {
            if (args.size() == 0 || args.size() == 1 && args.get(0) == null) {
                setDefaultConnection(null);
                return Void.TYPE;
            }

            if (args.size() != 1) {
                throw new TemplateModelException("Wrong number of arguments: expected 0 or 1, got " + args.size());
            }

            Object o = args.get(0);

            if (!(o instanceof StringModel)) {
                throw new TemplateModelException("Illegal type of argument: expected "
                        + StringModel.class.getName() + ", got " + o.getClass().getName());
            }

            StringModel sm = (StringModel) o;
            o = sm.getWrappedObject();

            if (o instanceof ConnectionAdapter) {
                setDefaultConnection((ConnectionAdapter) o);
            } else {
                throw new TemplateModelException("Illegal type of argument: expected "
                        + ConnectionAdapter.class.getName() + ", got " + o.getClass().getName());
            }

            return Void.TYPE;
        }

    }


}
