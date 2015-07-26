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


import freemarker.template.TemplateModel;
import freemarker.template.TemplateModelException;
import freemarker.template.Version;
import ftldb.ext.sql.*;

import java.sql.Array;
import java.sql.Clob;
import java.sql.Struct;


/**
 * The FTLDB's default object wrapper. Extends FreeMarker's wrapper with SQL type wrapping.
 *
 * <p>Registered wrappers are:
 * <ul>
 *     <li>{@link ArrayModel} - treats SQL collections ({@link Array}) as sequences
 *     <li>{@link ClobModel} - treats CLOBs ({@link Clob}) as strings
 *     <li>{@link StructModel} - treats UDTs ({@link Struct}) as sequences of elements
 *     <li>{@link FetchedResultSetModel} - treats fetched result sets ({@link FetchedResultSet}) as 2-layer objects
 * </ul>
 */
public class DefaultObjectWrapper extends freemarker.template.DefaultObjectWrapper {


    public DefaultObjectWrapper(Version incompatibleImprovements) {
        super(incompatibleImprovements);
    }


    protected TemplateModel handleUnknownType(Object obj) throws TemplateModelException {
        if (obj instanceof Array) {
            return new ArrayModel((Array) obj, this);
        }
        if (obj instanceof Clob) {
            return new ClobModel((Clob) obj, this);
        }
        if (obj instanceof Struct) {
            return new StructModel((Struct) obj, this);
        }
        if (obj instanceof FetchedResultSet) {
            return new FetchedResultSetModel((FetchedResultSet) obj, this);
        }
        return super.handleUnknownType(obj);
    }


}