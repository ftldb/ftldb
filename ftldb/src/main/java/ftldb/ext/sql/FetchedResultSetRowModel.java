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


import freemarker.template.*;

import java.util.Arrays;


/**
 * This class wraps {@link java.sql.ResultSet}'s row and adapts it for using in FTL both as a sequence and a hash of
 * rows.
 */
public class FetchedResultSetRowModel extends WrappingTemplateModel implements TemplateSequenceModel,
        TemplateHashModelEx {


    public final FetchedResultSet resultSet;
    public final int rowIndex;


    public FetchedResultSetRowModel(FetchedResultSet frs, int index, ObjectWrapper wrapper) {
        super(wrapper);
        this.resultSet = frs;
        this.rowIndex = index;
    }


    /**
     * Retrieves the i-th column in this row.
     *
     * @return the value of column at the specified index
     */
    public TemplateModel get(int index) throws TemplateModelException {
        return wrap(resultSet.data[rowIndex][index]);
    }


    /**
     * Retrieves the value of the specified column in this row.
     *
     * @return the value of the specified column
     */
    public TemplateModel get(String key) throws TemplateModelException {
        return wrap(resultSet.data[rowIndex][((Integer) resultSet.columnIndices.get(key)).intValue()]);
    }


    /**
     * Returns the row length.
     *
     * @return the number of columns in this row
     */
    public int size() {
        return resultSet.data[rowIndex].length;
    }


    /**
     * Returns a list of column names in this row.
     *
     * @return a list of column names ordered by position
     */
    public TemplateCollectionModel keys() throws TemplateModelException {
        return new SimpleCollection(Arrays.asList(resultSet.columnLabels), getObjectWrapper());
    }


    /**
     * Returns a list of values in this row.
     *
     * @return the list of values ordered by position
     */
    public TemplateCollectionModel values() throws TemplateModelException {
        return new SimpleCollection(java.util.Arrays.asList(resultSet.data[rowIndex]), getObjectWrapper());
    }


    /**
     * Determines whether the row is empty (contains no columns).
     *
     * @return always {@code false}
     */
    public boolean isEmpty() throws TemplateModelException {
        return resultSet.data[rowIndex].length == 0;
    }


}