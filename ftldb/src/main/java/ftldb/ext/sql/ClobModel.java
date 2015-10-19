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
import freemarker.template.SimpleCollection;
import freemarker.template.TemplateCollectionModel;
import freemarker.template.TemplateModelException;
import freemarker.template.TemplateScalarModel;

import java.sql.Clob;
import java.sql.SQLException;
import java.util.ArrayList;


/**
 * This class wraps {@link Clob} and adapts it for using in FTL as a string.
 */
public class ClobModel extends BeanModel implements TemplateScalarModel {


    private final String string;


    public ClobModel(Clob clob, BeansWrapper wrapper) throws TemplateModelException {
        super(clob, wrapper);
        try {
            this.string = clob.getSubString(1, (int) clob.length());
        } catch (SQLException e) {
            throw new TemplateModelException(e);
        }
    }


    /**
     * Returns the string representation of this clob.
     *
     * @return clob as a string
     */
    public String getAsString() throws TemplateModelException {
        return string;
    }


    /**
     * Returns the clob size.
     *
     * @return the number of characters
     */
    public int size() {
        return string.length();
    }


    /**
     * Returns the empty list. Iteration through the {@code super.values()} list causes an exception.
     *
     * @return the empty list
     */
    public TemplateCollectionModel values() {
        return new SimpleCollection(new ArrayList(0), wrapper);
    }


}