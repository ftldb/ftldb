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

import freemarker.ext.beans.StringModel;
import freemarker.template.SimpleScalar;
import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModelException;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;

/**
 * This class implements a factory of JDBC-connections for FTL.
 */
public class DBConnectionFactory {

    private DBConnection defaultDBConnection;


    /**
     * Implements a {@link TemplateMethodModelEx} FTL method interface. Creates a method named {@code new_connection}.
     * When it is called in FTL with no arguments, it returns the default connection provided by the database driver.
     * When it is called with 3 String arguments, it returns a connection initialized with them.
     *
     * @return an FTL method for getting a new database connection
     */
    public TemplateMethodModelEx getMethodNewDBConnection() {
        return new TemplateMethodModelEx() {
            public Object exec(List args) throws TemplateModelException {

                if (args.size() == 0) {
                    return newDBConnection();
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
                                + "expected SimpleScalar (i.e. String), got " + args.get(i).getClass().getName()
                        );
                    }
                }

                String url = strArgs[0];
                String user = strArgs[1];
                String password = strArgs[2];

                return newDBConnection(url, user, password);
            }
        };
    }


    /**
     * Implements a {@link TemplateMethodModelEx} FTL method interface. Creates a method named
     * {@code default_connection}. When it is called in FTL, it returns the default connection set for the factory
     * instance. By default it is {@code new_connection()}, but it can be overridden.
     *
     * @return an FTL method for getting the default database connection
     */
    public TemplateMethodModelEx getMethodGetDefaultDBConnection() {
        return new TemplateMethodModelEx() {
            public Object exec(List args) throws TemplateModelException {

                if (args.size() != 0) {
                    throw new TemplateModelException("Wrong number of arguments: expected 0, got " + args.size());
                }

                return getDefaultDBConnection();
            }
        };
    }


    /**
     * Implements a {@link TemplateMethodModelEx} FTL method interface. Creates a method named
     * {@code set_default_connection}. When it is called in FTL, it overrides the default connection for the factory
     * instance with its argument. In order to recover the default connection provided by the database driver,
     * the method with no arguments must be called in FTL.
     *
     * @return an FTL method for overriding the default database connection
     */
    public TemplateMethodModelEx getMethodSetDefaultDBConnection() {
        return new TemplateMethodModelEx() {
            public Object exec(List args) throws TemplateModelException {

                if (args.size() == 0 || args.size() == 1 && args.get(0) == null) {
                    setDefaultDBConnection(null);
                    return Void.TYPE;
                }

                if (args.size() != 1) {
                    throw new TemplateModelException("Wrong number of arguments: expected 0 or 1, got " + args.size());
                }

                Object o = args.get(0);

                if (!(o instanceof StringModel)) {
                    throw new TemplateModelException("Illegal type of argument: expected "
                            + StringModel.class.getName() + ", got " + o.getClass().getName()
                    );
                }

                StringModel sm = (StringModel) o;
                o = sm.getWrappedObject();

                if (o instanceof DBConnection) {
                    setDefaultDBConnection((DBConnection) o);
                } else {
                    throw new TemplateModelException("Illegal type of argument: expected "
                            + DBConnection.class.getName() + ", got " + o.getClass().getName()
                    );
                }

                return Void.TYPE;
            }
        };
    }


    /**
     * Gets the default connection from the {@link DriverManager} and returns it as a {@link DBConnection}
     * instance.
     *
     * @return a connection wrapped in a {@link DBConnection}
     * @throws TemplateModelException if a database access error occurs
     */
    public DBConnection newDBConnection() throws TemplateModelException {
        Connection conn;
        try {
            conn = DriverManager.getConnection("jdbc:default:connection");
        } catch (SQLException e) {
            throw new TemplateModelException(e);
        }
        return new DBConnection(conn);
    }


    /**
     * Gets a connection with the specified parameters and returns it as a {@link DBConnection} instance.
     *
     * @param url a database url of the form jdbc:subprotocol:subname
     * @param user the database user on whose behalf the connection is being made
     * @param password the user's password
     * @return a connection to the URL wrapped in a {@link DBConnection}
     * @throws TemplateModelException if a database access error occurs
     */
    public DBConnection newDBConnection(String url, String user, String password) throws TemplateModelException {
        Connection conn;
        try {
            conn = DriverManager.getConnection(url, user, password);
        } catch (SQLException e) {
            throw new TemplateModelException(e);
        }
        return new DBConnection(conn);
    }


    /**
     * Returns the default {@link DBConnection} set for the factory instance.
     *
     * @return the default connection wrapped in a {@link DBConnection}
     * @throws TemplateModelException if a database access error occurs
     */
    public synchronized DBConnection getDefaultDBConnection() throws TemplateModelException {
        if (defaultDBConnection == null) {
            defaultDBConnection = newDBConnection();
        }
        return defaultDBConnection;
    }


    /**
     * Overrides the default {@link DBConnection} for the factory instance.
     *
     * @param conn the new default {@link DBConnection}
     */
    public synchronized void setDefaultDBConnection(DBConnection conn) {
        defaultDBConnection = conn;
    }

}
