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

import freemarker.cache.StatefulTemplateLoader;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * This class implements a {@link StatefulTemplateLoader} factory that creates loaders from different databases.
 * Only Oracle DBMS is supported by now. Support of other databases is possible in future.
 */
public class DBTemplateLoaderFactory {

    /**
     * Returns an instance of {@link StatefulTemplateLoader} that is able to load templates from a database using
     * the specified connection and call.
     * @param connection the connection to a database where templates are stored
     * @param call the call to a database which extracts templates
     * @return a template loader instance
     */
    public static StatefulTemplateLoader newDBTemplateLoader(Connection connection, String call) {

        StatefulTemplateLoader dbTemplateLoader;
        String dbName;

        try {
            dbName = connection.getMetaData().getDatabaseProductName();
        } catch (SQLException e) {
            throw new RuntimeException("Unable to determine database product name", e);
        }

        if (dbName.equals("Oracle")) {
            dbTemplateLoader = new ftldb.oracle.DBTemplateLoader(connection, call);
        // May be in future...
        //} else if (dbName.equals("PostgreSQL")) {
        //    dbTemplateLoader = new ftldb.postgresql.DBTemplateLoader(conn, call);
        } else {
            throw new RuntimeException("No corresponding DBTemplateLoader class provided for " + dbName + " database");
        }

        return dbTemplateLoader;

    }

}
