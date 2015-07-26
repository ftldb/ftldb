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


import freemarker.ext.beans.BeanModel;
import freemarker.ext.beans.BeansWrapper;
import freemarker.template.*;


/**
 * This class wraps {@link FetchedResultSet} and adapts it for using in FTL both as a sequence of rows and as a bean.
 */
public class FetchedResultSetModel extends BeanModel implements TemplateSequenceModel, TemplateScalarModel {


    private ObjectWrapper wrapper;
    private FetchedResultSet frs;


    public FetchedResultSetModel(FetchedResultSet frs, BeansWrapper wrapper) throws TemplateModelException {
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


    /**
     * Get the specified property or method's result.
     *
     * @return the result of evaluation
     */
    public TemplateModel get(String key) throws TemplateModelException {
        if (key.equals("transpose")) {
            return new FetchedResultSetTransposedModel(frs, wrapper);
        }
        return super.get(key);
    }


    /**
     * Returns the result set as a text table with column headers. This method should be used for debugging only.
     * Usage example: {@code ${my_result}}.
     *
     * @return the result set as text
     */
    public String getAsString() {
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < frs.columnNames.length; i++) {
            sb.append(frs.columnNames[i]).append('\t');
        }
        sb.append('\n');
        for (int ri = 0; ri < frs.data.length; ri++) {
            for (int ci = 0; ci < frs.columnNames.length; ci++) {
                sb.append(frs.data[ri][ci]).append('\t');
            }
            sb.append('\n');
        }
        return sb.toString();
    }


}