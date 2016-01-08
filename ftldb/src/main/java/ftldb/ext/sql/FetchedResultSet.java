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


import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


/**
 * This class contains the static result of fetching from a {@link ResultSet} and its metadata. This is needed because
 * the original result set can be fetched only once, so wrapping it directly may lead to getting empty result set in
 * FTL if the object is accessed twice.
 */
public class FetchedResultSet {


    public final ResultSetMetaData metaData;
    public final String[] columnLabels;
    public final Map columnIndices;
    public final Object[][] data;


    /**
     * Fetches the specified result set and saves it as an {@link Object}[][]. Also saves its metadata.
     *
     * @param rs the original result set
     * @throws SQLException if a database access error occurs
     */
    public FetchedResultSet(ResultSet rs) throws SQLException {
        metaData = rs.getMetaData();
        int columnCount = metaData.getColumnCount();

        columnLabels = new String[columnCount];
        columnIndices = new HashMap(columnLabels.length, 1);

        for (int i = 0; i < columnCount; i++) {
            columnLabels[i] = metaData.getColumnLabel(i + 1);
            // if two columns have same labels, save only the 1st one
            if (columnIndices.get(columnLabels[i]) == null) {
                columnIndices.put(columnLabels[i], new Integer(i));
            }
        }

        List rows = new ArrayList(64);

        while (rs.next()) {
            Object[] row = new Object[columnCount];
            for (int i = 0; i < columnCount; i++) {
                Object o = rs.getObject(i + 1);
                if (o instanceof ResultSet) {
                    o = new FetchedResultSet((ResultSet) o);
                }
                row[i] = o;
            }
            rows.add(row);
        }

        data = (Object[][]) rows.toArray(new Object[rows.size()][columnCount]);

        rs.close();
    }


    /**
     * Returns the original {@link ResultSet}'s metadata.
     *
     * @return the metadata
     */
    public ResultSetMetaData getMetaData() {
        return metaData;
    }


    /**
     * Returns the specified column's index starting from 0. This index is used to access FTL sequences.
     *
     * @param label the column's label
     * @return the column's index or {@code null} if no column with such label exists
     */
    public Integer getColumnIndex(String label) {
        return (Integer) columnIndices.get(label);
    }


    /**
     * Returns the specified column's position starting from 1 as {@link ResultSet#findColumn(String)} does. This
     * index is used in {@link ResultSetMetaData} methods.
     *
     * @param label the column's label
     * @return the column's position or {@code null} if no column with such label exists
     */
    public Integer findColumn(String label) {
        Integer index = getColumnIndex(label);
        if (index == null) return null;
        return new Integer(index.intValue() + 1);
    }


    /**
     * @return this object
     * @deprecated Emulates v1.3.0 access method.
     */
    public FetchedResultSet getHashRows() {
        return this;
    }


    /**
     * @return this object
     * @deprecated Emulates v1.3.0 access method.
     */
    public FetchedResultSet getHash_rows() {
        return getHashRows();
    }


    /**
     * @return this object
     * @deprecated Emulates v1.3.0 access method.
     */
    public FetchedResultSet getSeqRows() {
        return this;
    }


    /**
     * @return this object
     * @deprecated Emulates v1.3.0 access method.
     */
    public FetchedResultSet getSeq_rows() {
        return getSeqRows();
    }


    /**
     * @return this object transposed
     * @deprecated Emulates v1.3.0 access method.
     */
    public FetchedResultSetTransposed getColHash() {
        return new FetchedResultSetTransposed(this);
    }


    /**
     * @return this object transposed
     * @deprecated Emulates v1.3.0 access method.
     */
    public FetchedResultSetTransposed getCol_hash() {
        return getColHash();
    }


    /**
     * @return this object transposed
     * @deprecated Emulates v1.3.0 access method.
     */
    public FetchedResultSetTransposed getColSeq() {
        return new FetchedResultSetTransposed(this);
    }


    /**
     * @return this object transposed
     * @deprecated Emulates v1.3.0 access method.
     */
    public FetchedResultSetTransposed getCol_seq() {
        return getColSeq();
    }


}
