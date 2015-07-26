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


import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;


/**
 * This class is a wrapper for working with JDBC connections in FTL.
 */
public class ConnectionAdapter {


    private final Connection connection;
    private QueryExecutor qe;
    private CallExecutor ce;


    /**
     * Creates an instance, wrapping the specified JDBC connection.
     *
     * @param connection the connection to be wrapped
     */
    public ConnectionAdapter(Connection connection) {
        this.connection = connection;
    }


    /**
     * Returns the inner JDBC connection.
     * @return the inner connection
     */
    public Connection getConnection() {
        return connection;
    }


    private synchronized QueryExecutor getQueryExecutor() {
        if (qe == null) {
            qe = new QueryExecutor(connection);
        }
        return qe;
    }


    private synchronized CallExecutor getCallExecutor() {
        if (ce == null) {
            ce = new CallExecutor(connection);
        }
        return ce;
    }


    /**
     * Executes an SQL query with the aid of the inner {@link QueryExecutor}.
     *
     * @param sql the SQL-query to be executed
     * @return the query result wrapped into {@link FetchedResultSetTransposedModel}
     * @throws SQLException if a database access error occurs
     */
    public FetchedResultSet query(String sql) throws SQLException {
        return getQueryExecutor().executeQuery(sql);
    }


    /**
     * Executes an SQL query with bind variables with the aid of the inner {@link QueryExecutor}.
     *
     * @param sql the SQL-query to be executed
     * @param binds the list of bind variable values
     * @return the query result wrapped into {@link FetchedResultSetTransposedModel}
     * @throws SQLException if a database access error occurs
     */
    public FetchedResultSet query(String sql, List binds) throws SQLException {
        return getQueryExecutor().executeQuery(sql, binds);
    }


    /**
     * Executes a callable statement with the aid of the inner {@link CallExecutor}.
     *
     * @param statement the callable statement to be executed
     * @param inBinds the map of in bind variable indices to their values
     * @param outBinds the map of out bind variable indices to their types
     * @return the map of out bind variable indices to their values
     * @throws SQLException if a database access error occurs
     */
    public Map exec(String statement, Map inBinds, Map outBinds) throws SQLException {
        return getCallExecutor().executeCall(statement, inBinds, outBinds);
    }


    /**
     * Closes the inner JDBC connection.
     *
     * @throws SQLException if a database access error occurs
     */
    public void close() throws SQLException {
        connection.close();
    }


}
