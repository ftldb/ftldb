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
import freemarker.template.TemplateModel;
import freemarker.template.TemplateModelException;
import freemarker.template.TemplateSequenceModel;

import java.sql.Array;
import java.sql.SQLException;


/**
 * This class wraps {@link Array} and adapts it for using in FTL both as a sequence and as a bean.
 */
public class ArrayModel extends BeanModel implements TemplateSequenceModel {


    protected final Object[] array;


    public ArrayModel(Array object, BeansWrapper wrapper) throws TemplateModelException {
        super(object, wrapper);
        try {
            this.array = (Object[]) object.getArray();
        } catch (SQLException e) {
            throw new TemplateModelException(e);
        }
    }


    /**
     * Retrieves the i-th element in this sequence.
     *
     * @return the item at the specified index
     */
    public TemplateModel get(int index) throws TemplateModelException {
        return wrap(array[index]);
    }


    /**
     * Returns the array size.
     *
     * @return the number of items in the list.
     */
    public int size() {//throws TemplateModelException {
        return array.length;
    }


}