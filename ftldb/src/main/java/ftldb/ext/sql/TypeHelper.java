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


import java.lang.reflect.Field;
import java.sql.Types;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;


/**
 * A helper class for working with SQL types.
 */
public class TypeHelper {


    // Map of SQL type names to their int values.
    private static final Map encoder = new HashMap();


    static {
        Field[] fields = Types.class.getFields();
        for (int i = 0; i < fields.length; i++) {
            try {
                String name = fields[i].getName();
                Object value = fields[i].get(null);
                if (value instanceof Integer) {
                    encoder.put(name, value);
                }
            } catch (IllegalAccessException e) {
                throw new RuntimeException("Unable to create map of SQL type names to int values", e);
            }
        }
    }


    /**
     * Returns an int value for the specified type name from {@link Types} or any other class containing
     * SQL type constants, for example {@link oracle.jdbc.OracleTypes}.
     *
     * @param typeName the constant name (fully specified, if not from {@link Types})
     * @return the corresponding Integer value
     * @throws Exception if a constant with the given name is not found, not accessible, not of int type or is null
     */
    public static Integer getIntValue(String typeName) throws Exception {
        Integer ret = (Integer) encoder.get(typeName);
        if (ret == null) {
            ret = extractConstant(typeName);
            encoder.put(typeName, ret);
        }
        return ret;
    }


    private static Integer extractConstant(String typeName) throws Exception {
        int lastDotPos = typeName.lastIndexOf(".");
        if (lastDotPos < 1) {
            throw new IllegalArgumentException("Type constant is not member of " + Types.class.getName()
                    + " and its name is not fully specified: " + typeName);
        }

        String className = typeName.substring(0, lastDotPos);
        String fieldName = typeName.substring(lastDotPos + 1);

        Class cls = Class.forName(className);
        Integer val = (Integer) cls.getField(fieldName).get(null);

        if (val == null) throw new NullPointerException(typeName);
        return val;
    }


    /**
     * Returns the specified object as an instance of an SQL-compatible subclass of {@link java.util.Date}:
     * either {@link java.sql.Date} or {@link java.sql.Timestamp}, depending on the presence of the time part.
     *
     * @param date the value to be converted
     * @return an SQL-compatible object
     */
    public static java.util.Date toSQLDate(java.util.Date date) {
        Calendar cal = Calendar.getInstance();
        cal.setTime(date);
        long millis = cal.getTimeInMillis();
        boolean hasTimePart = cal.get(Calendar.HOUR_OF_DAY) + cal.get(Calendar.MINUTE)
                + cal.get(Calendar.SECOND) + cal.get(Calendar.MILLISECOND) != 0;
        return hasTimePart ? (java.util.Date) new java.sql.Timestamp(millis) : new java.sql.Date(millis);
    }

}
