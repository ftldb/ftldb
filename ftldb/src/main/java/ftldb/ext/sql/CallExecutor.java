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


import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;


/**
 * This class is a database callable statement executor.
 */
public class CallExecutor {


    private final Connection connection;


    /**
     * Creates a new instance using the specified connection.
     *
     * @param connection the connection to a database
     */
    public CallExecutor(Connection connection) {
        this.connection = connection;
    }


    /**
     * Executes the specified call using the specified bind variables. The keys of {@code inBinds} and {@code outBinds}
     * maps must be integers starting from 1 presented as Strings (quoted) due to limits of FTL Hash type. The names of
     * bind variables in the call are ignored. Variables with the same names are treated as different.
     *
     * @param call the callable statement to be executed
     * @param inBinds the map of in bind variable indices to their values
     * @param outBinds the map of out bind variable indices to their type names
     * @return a map of out bind variable indices to their values
     * @throws SQLException if a database access error occurs
     */
    public Map executeCall(String call, Map inBinds, Map outBinds) throws SQLException {
        if (call == null || "".equals(call.trim())) {
            throw new SQLException("Unable to execute empty call");
        }
        if (inBinds == null) inBinds = Collections.EMPTY_MAP;
        if (outBinds == null) outBinds = Collections.EMPTY_MAP;
        return executeCallInternal(call, inBinds, outBinds);
    }


    private Map executeCallInternal(String call, Map inBinds, Map outBinds) throws SQLException {

        CallableStatement cs = connection.prepareCall(call);

        for (Iterator it = inBinds.entrySet().iterator(); it.hasNext(); ) {
            Map.Entry e = (Map.Entry) it.next();

            int index;
            try {
                index = Integer.parseInt(e.getKey().toString());
            } catch (NumberFormatException ex) {
                throw new SQLException("Wrong in bind variable index: expected int, got String", ex);
            }

            Object o = e.getValue();
            // JDBC can't work with java.util.Date directly
            if (o instanceof Date) o = TypeHelper.toSQLDate((Date) o);
            cs.setObject(index, o);
        }

        for (Iterator it = outBinds.entrySet().iterator(); it.hasNext(); ) {
            Map.Entry e = (Map.Entry) it.next();

            int index;
            try {
                index = Integer.parseInt(e.getKey().toString());
            } catch (NumberFormatException ex) {
                throw new SQLException("Wrong out bind variable index: expected int, got String", ex);
            }

            Object o = e.getValue();
            String typeName;

            if (o instanceof String) {
                typeName = (String) o;
            } else {
                throw new SQLException("Unable to register type of out bind variable #" + index + ": " + o);
            }

            String sqlTypeName;
            String usrTypeName;
            int delimIndex = typeName.indexOf(":");

            if ( delimIndex == -1) {
                sqlTypeName = typeName;
                usrTypeName = null;
            } else {
                sqlTypeName = typeName.substring(0, delimIndex);
                usrTypeName = typeName.substring(delimIndex + 1);
            }

            Integer sqlType;
            try {
                sqlType = TypeHelper.getIntValue(sqlTypeName);
            } catch (Exception ex) {
                throw new SQLException("Unknown SQL type of out bind variable #" + index + ": " + sqlTypeName, ex);
            }

            if (usrTypeName == null || "".equals(usrTypeName.trim())) {
                cs.registerOutParameter(index, sqlType.intValue());
            } else {
                cs.registerOutParameter(index, sqlType.intValue(), usrTypeName);
            }

        }

        cs.execute();

        Map ret = new HashMap(outBinds.size(), 1);
        for (Iterator it = outBinds.entrySet().iterator(); it.hasNext(); ) {
            Map.Entry e = (Map.Entry) it.next();
            int index = Integer.parseInt(e.getKey().toString());
            Object retBind = cs.getObject(index);
            if (retBind instanceof ResultSet) {
                retBind = new FetchedResultSet((ResultSet) retBind);
            }
            ret.put(String.valueOf(index), retBind);
        }

        return ret;

    }


}
