/*
 * Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy
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


import java.sql.*;
import java.util.*;
import java.util.Date;


/**
 * This class is a database query executor. The result of each query is fully fetched and placed in memory, so be
 * careful while working with very large queries. Columns are got with {@link ResultSet#getObject(int)} and saved as is,
 * preserving their types.
 */
public class QueryExecutor {


    private final Connection connection;


    /**
     * Creates a new instance using the specified connection.
     *
     * @param connection the connection to a database
     */
    public QueryExecutor(Connection connection) {
        this.connection = connection;
    }


    /**
     * Executes the specified query.
     *
     * @param query the SQL query statement
     * @return the result set wrapped into {@link FetchedResultSet}
     * @throws SQLException if a database access error occurs
     */
    public FetchedResultSet executeQuery(String query) throws SQLException {
        return executeQuery(query, null);
    }


    /**
     * Executes the specified query containing bind variables.
     *
     * @param query the SQL query statement
     * @param binds the list of bind variable values
     * @return the result set wrapped into {@link FetchedResultSet}
     * @throws SQLException if a database access error occurs
     */
    public FetchedResultSet executeQuery(String query, List binds) throws SQLException {
        if (query == null || "".equals(query.trim())) {
            throw new RuntimeException("Unable to execute empty query");
        }
        if (binds == null) binds = Collections.EMPTY_LIST;

        PreparedStatement ps = connection.prepareStatement(query);

        if (binds != null && !binds.isEmpty()) {
            int index = 1;
            for (Iterator it = binds.iterator(); it.hasNext(); ) {
                Object o = it.next();
                // JDBC can't work with java.util.Date directly
                if (o instanceof Date) o = TypeHelper.toSQLDate((Date) o);
                ps.setObject(index++, o);
            }
        }

        return new FetchedResultSet(ps.executeQuery());
    }


}
