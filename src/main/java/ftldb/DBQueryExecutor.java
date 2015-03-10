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


import java.sql.*;
import java.util.*;
import java.util.Date;


/**
 * This class is a database query executor. The result of each query is fully fetched and placed in memory, so be
 * careful while working with very large queries. Columns are got with {@link ResultSet#getObject(int)} and saved as is,
 * preserving their types.
 */
public class DBQueryExecutor {

    private final Connection connection;


    /**
     * Creates a new instance using the specified connection.
     *
     * @param connection the connection to a database
     */
    public DBQueryExecutor(Connection connection) {
        this.connection = connection;
    }


    /**
     * Executes the specified query.
     *
     * @param query the SQL query statement
     * @return the result set wrapped in {@link QueryResult}
     * @throws SQLException if a database access error occurs
     */
    public QueryResult executeQuery(String query) throws SQLException {
        return executeQuery(query, null);
    }


    /**
     * Executes the specified query containing bind variables.
     *
     * @param query the SQL query statement
     * @param binds the list of bind variable values
     * @return the result set wrapped in {@link QueryResult}
     * @throws SQLException if a database access error occurs
     */
    public QueryResult executeQuery(String query, List binds) throws SQLException {
        if (query == null || "".equals(query.trim())) {
            throw new RuntimeException("Unable to execute empty query");
        }
        if (binds == null) binds = Collections.EMPTY_LIST;

        PreparedStatement ps = connection.prepareStatement(query);
        try {
            if (binds != null && !binds.isEmpty()) {
                int index = 1;
                for (Iterator it = binds.iterator(); it.hasNext(); ) {
                    Object o = it.next();
                    // JDBC can't work with java.util.Date directly
                    if (o instanceof Date) o = SQLTypeHelper.toSQLDate((Date) o);
                    ps.setObject(index++, o);
                }
            }
            ResultSet rs = ps.executeQuery();

            return processResultSet(rs);
        } finally {
            ps.close();
        }
    }


    /**
     * Wraps the specified result set in an instance of {@link QueryResult}.
     *
     * @param rs the result set
     * @return the result set and its column metadata wrapped as a single object
     * @throws SQLException if a database access error occurs
     */
    public static QueryResult processResultSet(ResultSet rs) throws SQLException {
        try {
            ResultSetMetaData rsmd = rs.getMetaData();
            int colCount = rsmd.getColumnCount();
            List colMetaList = new ArrayList(colCount);
            for (int i = 1; i <= colCount; i++) {
                ColumnMetaData cmd = new ColumnMetaData(rsmd, i);
                colMetaList.add(cmd);
            }
            return new QueryResult(colMetaList, rs);
        } finally {
            rs.close();
        }
    }


    /**
     * The result of query execution, containing the result set and the column metadata. This object can be used in FTL.
     *
     * <p>The result set itself is stored internally as a 2-dimensional array and can be represented in FTL in four
     * different ways as:
     * <ul>
     *     <li>a sequence of rows, each represented as:
     *     <ul>
     *         <li>a sequence of columns - see {@link QueryResult#getSeqRows};
     *         <li>a hash of columns - see {@link QueryResult#getHashRows};
     *     </ul>
     *     <li>a sequence of columns, each presented as a sequence of rows - see {@link QueryResult#getColSeq};
     *     <li>a hash of columns, each presented as a sequence of rows - see {@link QueryResult#getColHash};
     * </ul>
     *
     * <p>where 'sequence' and 'hash' are inner FTL types, analogues of {@link List} and {@link Map}. Rows and columns
     * in a sequence are accessed by their indices starting from 0, e.g. {@code rows[3]}. Columns in a hash are
     * accessed by their names (case-sensitive), e.g. {@code columns["NAME"]} or {@code columns.ID}.
     *
     * <p>The assymmetry in method naming is intentional. Getting the result set with the first two methods you get
     * a sequence of either {@code seqRow} or {@code hashRow} objects. The plural form just means 'sequence'.
     *
     * <p>Getting the result set with the rest two methods you get a collection of columns: either a sequence or a hash,
     * so you specify the type of collection explicitly. No 'Seq' prefix is needed, because a column is always
     * a sequence.
     */
    public static class QueryResult {

        private final Object[][] data;
        private final ColumnMetaData[] colMetaArr;
        private Map colMetaMap;


        private QueryResult(List colMetaList, ResultSet rs) throws SQLException {
            int colCount = colMetaList.size();

            this.colMetaArr = (ColumnMetaData[]) colMetaList.toArray(new ColumnMetaData[colCount]);

            List tmpRows = new ArrayList(64);

            while (rs.next()) {
                Object[] currRow = new Object[colCount];
                for (int i = 1; i <= colCount; i++) {
                    Object obj = rs.getObject(i);
                    if (obj instanceof ResultSet) {
                        obj = processResultSet((ResultSet) obj);
                    }
                    currRow[i - 1] = obj;
                }
                tmpRows.add(currRow);
            }
            this.data = (Object[][]) tmpRows.toArray(new Object[tmpRows.size()][colCount]);
        }


        /**
         * Returns the column metadata for a result set as a sequence of {@link ColumnMetaData} accessed by the column
         * index, starting from 0.
         *
         * @return the column metadata array
         */
        public ColumnMetaData[] getColMetaSeq() {
            return colMetaArr;
        }


        /**
         * FTL-style alias for {@link #getColMetaSeq()} accessible as {@code .col_meta_seq} attribute.
         *
         * @return the column metadata array
         */
        public ColumnMetaData[] getCol_meta_seq() {
            return getColMetaSeq();
        }


        /**
         * Returns the column metadata for a result set as a hash of {@link ColumnMetaData} accessed by the column name
         * (case-sensitive).
         *
         * @return the column metadata map
         */
        public synchronized Map getColMetaHash() {
            if (colMetaMap == null) {
                colMetaMap = new HashMap(colMetaArr.length);
                for (int i = 0; i < colMetaArr.length; i++) {
                    colMetaMap.put(colMetaArr[i].getName(), colMetaArr[i]);
                }
            }
            return colMetaMap;
        }


        /**
         * FTL-style alias for {@link #getColMetaHash()} accessible as {@code .col_meta_hash} attribute.
         *
         * @return the column metadata map
         */
        public Map getCol_meta_hash() {
            return getColMetaHash();
        }


        /**
         * Returns the column metadata for a result set as a sequence of sequences accessed by the row and column
         * indices, both starting from 0.
         *
         * @return the result set as a 2-dimensional array
         */
        public Object[][] getSeqRows() {
            return data;
        }


        /**
         * FTL-style alias for {@link #getSeqRows()} accessible as {@code .seq_rows} attribute.
         *
         * @return the result set as a 2-dimensional array
         */
        public Object[][] getSeq_rows() {
            return getSeqRows();
        }


        /**
         * Returns the column metadata for a result set as a sequence of hashes accessed by the row index starting from
         * 0 and the column name (case-sensitive).
         *
         * @return the result set as an array of maps
         */
        public Map[] getHashRows() {
            Map[] ret = new Map[data.length];
            for (int ri = 0; ri < ret.length; ri++) {
                ret[ri] = new HashMap(colMetaArr.length);
                for (int ci = 0; ci < colMetaArr.length; ci++) {
                    ColumnMetaData cmd = colMetaArr[ci];
                    ret[ri].put(cmd.getName(), data[ri][ci]);
                }
            }
            return ret;
        }


        /**
         * FTL-style alias for {@link #getHashRows()} accessible as {@code .hash_rows} attribute.
         *
         * @return the result set as an array of maps
         */
        public Map[] getHash_rows() {
            return getHashRows();
        }


        /**
         * Returns the column metadata for a result set as a sequence of sequences accessed by the column and row
         * indices, both starting from 0. This is a transposed result of {@link #getSeqRows()} method.
         *
         * @return the result set as a 2-dimensional array
         */
        public Object[][] getColSeq() {
            Object[][] ret = new Object[colMetaArr.length][];
            for (int rowInd = 0; rowInd < data.length; rowInd++) {
                for (int colInd = 0; colInd < colMetaArr.length; colInd++) {
                    if (ret[colInd] == null) ret[colInd] = new Object[data.length];
                    ret[colInd][rowInd] = data[rowInd][colInd];
                }
            }
            return ret;
        }


        /**
         * FTL-style alias for {@link #getColSeq()} accessible as {@code .col_seq} attribute.
         *
         * @return the result set as a 2-dimensional array
         */
        public Object[][] getCol_seq() {
            return getColSeq();
        }


        /**
         * Returns the column metadata for a result set as a hash of sequences accessed by the column name
         * (case-sensitive) and the row index starting from 0. This is a transposed result of {@link #getHashRows()}
         * method.
         *
         * @return the result set as a map of arrays
         */
        public Map getColHash() {
            Map ret = new HashMap(colMetaArr.length);
            for (int colInd = 0; colInd < colMetaArr.length; colInd++) {
                Object[] colData = new Object[data.length];
                ret.put(colMetaArr[colInd].getName(), colData);
                for (int rowInd = 0; rowInd < data.length; rowInd++) {
                    colData[rowInd] = data[rowInd][colInd];
                }
            }
            return ret;
        }


        /**
         * FTL-style alias for {@link #getColHash()} accessible as {@code .col_hash} attribute.
         *
         * @return the result set as a map of arrays
         */
        public Map getCol_hash() {
            return getColHash();
        }


        /**
         * Returns the result set as a text table with column headers. This method should be used for debugging only.
         * Usage example: {@code ${my_result}}.
         *
         * @return the result set as a text
         */
        public String toString() {
            StringBuffer sb = new StringBuffer();
            for (int i = 0; i < colMetaArr.length; i++) {
                sb.append(colMetaArr[i].getName()).append('\t');
            }
            sb.append('\n');
            for (int ri = 0; ri < this.data.length; ri++) {
                for (int ci = 0; ci < colMetaArr.length; ci++) {
                    sb.append(data[ri][ci]).append('\t');
                }
                sb.append('\n');
            }
            return sb.toString();
        }
    }


    /**
     * This class contains metadata for a single column from a result set. All the properties of this class and their
     * descriptions are got from {@link ResultSetMetaData}.
     *
     * @see ResultSetMetaData
     */
    public static class ColumnMetaData {

        private final int index;
        private final String name;
        private final String typeName;
        private final int precision;
        private final int scale;
        private final int nullable;


        private ColumnMetaData(ResultSetMetaData rsmd, int colIndex) throws SQLException {
            this.index = colIndex;
            this.name = rsmd.getColumnName(colIndex);
            this.typeName = rsmd.getColumnTypeName(colIndex);
            this.precision = rsmd.getPrecision(colIndex);
            this.scale = rsmd.getScale(colIndex);
            this.nullable = rsmd.isNullable(colIndex);
        }


        /**
         * Get the column's index, starting from 1.
         *
         * @return column index
         */
        public int getIndex() {
            return index;
        }


        /**
         * Get the column's name. See {@link ResultSetMetaData#getColumnName(int)}.
         *
         * @return column name
         */
        public String getName() {
            return name;
        }


        /**
         * Retrieves the column's database-specific type name. See {@link ResultSetMetaData#getColumnTypeName(int)}.
         *
         * @return type name used by the database
         */
        public String getTypeName() {
            return typeName;
        }


        /**
         * Get the column's specified column size. See {@link ResultSetMetaData#getPrecision(int)}.
         *
         * @return precision
         */
        public int getPrecision() {
            return precision;
        }


        /**
         * Gets the column's number of digits to right of the decimal point.
         * See {@link ResultSetMetaData#getScale(int)}.
         *
         * @return scale
         */
        public int getScale() {
            return scale;
        }


        /**
         * Indicates the nullability of values in the column. See {@link ResultSetMetaData#isNullable(int)}.
         *
         * @return the nullability status of the given column
         */
        public int getNullable() {
            return nullable;
        }


        /**
         * Returns the column description as a string. This method should be used for debugging only.
         *
         * @return column description
         */
        public String toString() {
            return
                    "index=" + index +
                            "  name=" + name +
                            ", typeName=" + typeName +
                            ", precision=" + precision +
                            ", scale=" + scale +
                            ", nullable=" + nullable
                    ;
        }

    }

}
