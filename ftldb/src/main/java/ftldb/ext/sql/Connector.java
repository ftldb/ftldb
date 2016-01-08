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


import freemarker.core.Environment;
import freemarker.ext.beans.BeanModel;
import freemarker.template.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.Properties;


/**
 * This class manages JDBC connections for FTL. It contains private methods for constructing
 * {@link ConnectionAdapter}s and public static classes for FTL.
 */
public class Connector {


    // The default connection set for the configuration.
    private static ConnectionAdapter defaultConnection;


    private static ConnectionAdapter newConnection(String url, Properties info)
            throws TemplateModelException {
        try {
            Connection connection = DriverManager.getConnection(url, info);
            connection.setAutoCommit(false);
            return new ConnectionAdapter(connection);
        } catch (SQLException e) {
            throw new TemplateModelException(e);
        }
    }


    private static ConnectionAdapter newConnection(String url, String user, String password)
            throws TemplateModelException {
        Properties info = new Properties();
        if (user != null) info.setProperty("user", user);
        if (password != null) info.setProperty("password", password);
        return newConnection(url, info);
    }


    private static ConnectionAdapter newConnection(String url)
            throws TemplateModelException {
        return newConnection(url, new Properties());
    }


    private static ConnectionAdapter newConnection() throws TemplateModelException {
        return newConnection("jdbc:default:connection");
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
     * <p>Method definition: {@code ConnectionAdapter new_connection(String url, TemplateHashModel info)}
     * <p>Method arguments:
     * <pre>
     *     {@code url} - a database url of the form <code>jdbc:<em>subprotocol</em>:<em>subname</em></code>
     *     {@code info} - a list of arbitrary string tag/value pairs as connection arguments
     * </pre>
     *
     * <p>Method overloading: {@code ConnectionAdapter new_connection(String url, String user, String password)}
     * <p>Method arguments:
     * <pre>
     *     {@code url} - a database url of the form <code>jdbc:<em>subprotocol</em>:<em>subname</em></code>
     *     {@code user} - the database user on whose behalf the connection is being made
     *     {@code password} - the user's password
     * </pre>
     *
     * <p>Method overloading: {@code ConnectionAdapter new_connection(String url)}.
     * <p>Method arguments:
     * <pre>
     *     {@code url} - a database url of the form <code>jdbc:<em>subprotocol</em>:<em>subname</em></code>
     * </pre>
     *
     * <p>Method overloading: {@code ConnectionAdapter new_connection()}. Returns the driver's default connection with
     * the {@code "jdbc:default:connection"} url.
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * <#assign inner_conn = new_connection()/>
     * <#assign ext_conn1 = new_connection("jdbc:oracle:thin:scott/tiger@//localhost:1521/orcl")/>
     * <#assign ext_conn2 = new_connection("jdbc:oracle:thin:@//localhost:1521/orcl", "scott", "tiger")/>
     * <#assign ext_conn3 = new_connection("jdbc:oracle:thin:@//localhost:1521/orcl", {"user" : "scott", "password" : "tiger"}/>
     * }
     * </pre>
     */
    public static class NewConnectionMethod implements TemplateMethodModelEx {

        public Object exec(List args) throws TemplateModelException {

            if (args.size() > 3) {
                throw new TemplateModelException("Wrong number of arguments: expected 0 to 3, got " + args.size());
            }

            if (args.size() == 0) {
                return newConnection();
            }

            if (args.size() == 1) {
                Object o = args.get(0);
                String url;
                if (!(o instanceof TemplateScalarModel)) {
                    throw new TemplateModelException("Illegal type of argument #1: "
                            + "expected string, got " + o.getClass().getName());
                }
                url = ((TemplateScalarModel) o).getAsString();
                return newConnection(url);
            }

            if (args.size() == 2) {
                Object o = args.get(0);
                String url;
                if (!(o instanceof TemplateScalarModel)) {
                    throw new TemplateModelException("Illegal type of argument #1: "
                            + "expected string, got " + o.getClass().getName());
                }
                url = ((TemplateScalarModel) o).getAsString();

                o = args.get(1);
                Properties info = new Properties();
                if (!(o instanceof TemplateHashModelEx)) {
                    throw new TemplateModelException("Illegal type of argument #2: "
                            + "expected hash, got " + o.getClass().getName());
                }
                TemplateHashModelEx hash = (TemplateHashModelEx) o;
                TemplateModelIterator it = hash.keys().iterator();
                while (it.hasNext()) {
                    Object keyObj = it.next();
                    if (!(keyObj instanceof TemplateScalarModel)) {
                        throw new TemplateModelException("Illegal type of property key: "
                                + "expected string, got " + keyObj.getClass().getName());
                    }
                    String key = ((TemplateScalarModel) keyObj).getAsString();
                    Object valObj = hash.get(key);
                    if (!(valObj instanceof TemplateScalarModel)) {
                        throw new TemplateModelException("Illegal type of property value: "
                                + "expected string, got " + valObj.getClass().getName());
                    }
                    String val = ((TemplateScalarModel) valObj).getAsString();
                    info.setProperty(key, val);
                }

                return newConnection(url, info);
            }

            // else if args.size() == 3
            String[] strArgs = new String[3];
            for (int i = 0; i < 3; i++) {
                Object o = args.get(i);
                if (!(o instanceof TemplateScalarModel)) {
                    throw new TemplateModelException("Illegal type of argument #" + (i + 1) + ": "
                            + "expected string, got " + o.getClass().getName());
                }
                strArgs[i] = ((TemplateScalarModel) o).getAsString();
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
     * This class implements an FTL directive named {@code set_default_connection} that sets the default {@link
     * ConnectionAdapter} instance for the configuration.
     *
     * <p>Directive definition: {@code set_default_connection(ConnectionAdapter conn)}
     * <p>Method arguments:
     * <pre>
     *     {@code conn} - the new default connection
     * </pre>
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * <#assign ext_conn = new_connection("jdbc:oracle:thin@//localhost:1521/orcl", "scott", "tiger")/>
     * <@set_default_connection conn = ext_conn/>
     * }
     * </pre>
     */
    public static class SetDefaultConnectionDirective implements TemplateDirectiveModel {

        private static final String PARAM_NAME_CONN = "conn";

        public void execute(Environment env, Map params, TemplateModel[] loopVars, TemplateDirectiveBody body)
                throws TemplateException, IOException {
            if (body != null) {
                throw new TemplateModelException("Wrong usage: body is not allowed");
            }
            if (loopVars.length != 0) {
                throw new TemplateModelException("Wrong usage: loop variables are not allowed");
            }
            if (params.size() != 1) {
                throw new TemplateModelException("Wrong number of named parameters: expected 1, got " + params.size());
            }
            if (!params.containsKey(PARAM_NAME_CONN)) {
                throw new TemplateModelException("Wrong parameter name: expected \"" + PARAM_NAME_CONN + "\", got \""
                        + params.keySet().toArray()[0] + "\"");
            }

            Object o = params.get(PARAM_NAME_CONN);

            if (!(o instanceof BeanModel) || !((o = ((BeanModel) o).getWrappedObject()) instanceof ConnectionAdapter)) {
                throw new TemplateModelException("Illegal type of parameter \"" + PARAM_NAME_CONN + "\": expected "
                        + ConnectionAdapter.class.getName() + ", got " + o.getClass().getName());
            }

            setDefaultConnection((ConnectionAdapter) o);
        }

    }


}
