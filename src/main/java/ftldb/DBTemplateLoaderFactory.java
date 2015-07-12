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
 * This class implements a {@link StatefulTemplateLoader} factory that creates loaders for different databases.
 * Only Oracle DBMS is supported by now. Support of other databases is possible in future.
 */
public class DBTemplateLoaderFactory {

    /**
     * Returns an instance of {@link StatefulTemplateLoader} that is able to load templates from a database using
     * the specified connection and calls.
     * @param conn a connection to a database where templates are stored
     * @param templateResolverCall a call to the database that resolves a template's name
     * @param templateCheckerCall a call to the database that gets a template's timestamp
     * @param templateLoaderCall a call to the database that returns a template's source
     * @return a template loader instance
     */
    public static StatefulTemplateLoader newDBTemplateLoader(
            Connection conn, String templateResolverCall, String templateCheckerCall, String templateLoaderCall
    ) {

        StatefulTemplateLoader dbTemplateLoader;
        String dbName;

        try {
            dbName = conn.getMetaData().getDatabaseProductName();
        } catch (SQLException e) {
            throw new RuntimeException("Unable to determine database product name", e);
        }

        if (dbName.equals("Oracle")) {
            dbTemplateLoader = new ftldb.oracle.DBTemplateLoader(
                    conn, templateResolverCall, templateCheckerCall, templateLoaderCall
            );
        } else {
            throw new RuntimeException("No corresponding DBTemplateLoader implementation provided for " +
                    dbName + " database");
        }

        return dbTemplateLoader;

    }

}
