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
package ftldb.oracle;


import java.sql.Clob;
import java.sql.SQLException;


/**
 * Extension of {@link ftldb.Configurator} for working with the configuration in Oracle Database via JDBC interfaces,
 * which can be directly mapped to PL/SQL types.
 */
public class Configurator extends ftldb.Configurator {


    /**
     * The convenience method for {@link #setConfiguration(java.io.InputStream)}.
     *
     * @param configXMLClob the new configuration as an XML clob
     */
    public static void setConfiguration(Clob configXMLClob) throws SQLException {
        setConfiguration(configXMLClob.getAsciiStream());
    }


    /**
     * Returns FTLDB version as a string.
     *
     * @return FTLDB version
     */
    public static String getVersionString() {
        return getVersion().toString();
    }


    /**
     * Returns FTLDB version as a comparable integer.
     *
     * @return FTLDB version
     */
    public static int getVersionNumber() {
        return getVersion().intValue();
    }


}
