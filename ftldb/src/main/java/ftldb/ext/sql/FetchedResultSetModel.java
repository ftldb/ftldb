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


import freemarker.core.CollectionAndSequence;
import freemarker.ext.beans.BeanModel;
import freemarker.ext.beans.BeansWrapper;
import freemarker.template.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;


/**
 * This class wraps {@link FetchedResultSet} and adapts it for using in FTL both as a sequence of rows and as a bean.
 */
public class FetchedResultSetModel extends BeanModel implements TemplateSequenceModel, TemplateScalarModel {


    private final ObjectWrapper wrapper;
    private final FetchedResultSet frs;


    public FetchedResultSetModel(FetchedResultSet frs, BeansWrapper wrapper) {
        super(frs, wrapper);
        this.wrapper = wrapper;
        this.frs = frs;
    }


    /**
     * Retrieves the i-th row in this result set.
     *
     * @return the row at the specified index (rownum - 1)
     */
    public TemplateModel get(int index) throws TemplateModelException {
        return new FetchedResultSetRowModel(frs, index, wrapper);
    }


    /**
     * Returns the row count.
     *
     * @return the number of rows in this result set
     */
    public int size() {
        return frs.data.length;
    }


    private final static String TRANSPOSE_METHOD_NAME = "transpose";


    /**
     * Get the specified property or method's result.
     *
     * @return the result of evaluation
     */
    public TemplateModel get(String key) throws TemplateModelException {
        if (key.equals(TRANSPOSE_METHOD_NAME)) {
            return transpose();
        }
        return super.get(key);
    }


    /**
     * Returns the transposed result set as a {@link FetchedResultSetTransposedModel}.
     *
     * @return the transposed result set
     */
    public TemplateModel transpose() {
        return new TemplateMethodModelEx() {
            public Object exec(List args) throws TemplateModelException {
                if (args.size() != 0) {
                    throw new TemplateModelException("No arguments needed");
                }
                return wrap(new FetchedResultSetTransposed(frs));
            }
        };
    }


    /**
     * Returns the list of available methods and properties, extended by own methods.
     *
     * @return the collection of methods and properties
     */
    public TemplateCollectionModel keys() {
        Set keySetEx = super.keySet();
        keySetEx.add(TRANSPOSE_METHOD_NAME);
        return new CollectionAndSequence(new SimpleSequence(keySetEx, wrapper));
    }


    /**
     * Returns the empty list. Iteration through the {@code super.values()} list causes an exception.
     *
     * @return the empty list
     */
    public TemplateCollectionModel values() {
        return new SimpleCollection(new ArrayList(0), wrapper);
    }


    /**
     * Returns the result set as a text table with column headers. This method should be used for debugging only.
     * Usage example: {@code ${my_result}}.
     *
     * @return the result set as text
     */
    public String getAsString() {
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < frs.columnLabels.length; i++) {
            sb.append(frs.columnLabels[i]).append('\t');
        }
        sb.append('\n');
        for (int ri = 0; ri < frs.data.length; ri++) {
            for (int ci = 0; ci < frs.columnLabels.length; ci++) {
                sb.append(frs.data[ri][ci]).append('\t');
            }
            sb.append('\n');
        }
        return sb.toString();
    }


}