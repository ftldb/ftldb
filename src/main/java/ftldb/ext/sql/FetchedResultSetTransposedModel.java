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


import freemarker.template.*;


/**
 * This class wraps {@link FetchedResultSetTransposed} and adapts it for using in FTL both as a sequence and a hash of
 * columns.
 */
public class FetchedResultSetTransposedModel extends WrappingTemplateModel implements TemplateSequenceModel,
        TemplateHashModelEx {


    public final FetchedResultSetTransposed frst;


    public FetchedResultSetTransposedModel(FetchedResultSetTransposed frst, ObjectWrapper wrapper)
            throws TemplateModelException {
        super(wrapper);
        this.frst = frst;
    }


    /**
     * Retrieves the i-th column of this result set.
     *
     * @return the column at the specified index
     */
    public TemplateModel get(int index) throws TemplateModelException {
        return wrap(frst.transposedData[index]);
    }


    /**
     * Retrieves the specified column in this result set.
     *
     * @return the specified column as an array
     */
    public TemplateModel get(String key) throws TemplateModelException {
        return wrap(frst.transposedData[((Integer) frst.resultSet.columnIndices.get(key)).intValue()]);
    }


    /**
     * Returns the row length.
     *
     * @return the number of columns in this result set
     */
    public int size() {
        return frst.transposedData.length;
    }


    /**
     * Returns a list of column names in this result set.
     *
     * @return a list of column names ordered by position
     */
    public TemplateCollectionModel keys() throws TemplateModelException {
        return new SimpleCollection(java.util.Arrays.asList(frst.resultSet.columnLabels), getObjectWrapper());
    }


    /**
     * Returns a list of columns in this result set.
     *
     * @return the list of column arrays ordered by position
     */
    public TemplateCollectionModel values() throws TemplateModelException {
        return new SimpleCollection(java.util.Arrays.asList(frst.transposedData), getObjectWrapper());
    }


    /**
     * Determines whether the result set contains no columns.
     *
     * @return always {@code false}
     */
    public boolean isEmpty() throws TemplateModelException {
        return frst.transposedData.length == 0;
    }


}