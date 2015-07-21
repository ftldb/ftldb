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

import java.sql.Clob;
import java.sql.SQLException;


/**
 * This class wraps {@link Clob} and adapts it for using in FTL as a string.
 */
public class ClobAdapter extends WrappingTemplateModel implements TemplateScalarModel, AdapterTemplateModel {


    private final Clob clob;


    public ClobAdapter(Clob clob, ObjectWrapper ow) {
        super(ow);
        this.clob = clob;
    }


    /**
     * Returns the wrapped clob.
     *
     * @return clob itself
     */
    public Object getAdaptedObject(Class hint) {
        return clob;
    }


    /**
     * Returns the string representation of this clob.
     *
     * @return clob as a string
     */
    public String getAsString() throws TemplateModelException {
        try {
            return clob.getSubString(1, (int) clob.length());
        } catch (SQLException e) {
            throw new TemplateModelException(e);
        }
    }


}