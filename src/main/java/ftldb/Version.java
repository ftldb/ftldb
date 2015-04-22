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


/**
 * This class contains and returns the FTLDB version.
 *
 * Generated from templates/ftldb/Version.java.template.
 */
public final class Version {

    private final static String STRING_VALUE;
    private final static int INT_VALUE;

    static {
        String projectVersion = "1.2.2-SNAPSHOT";
        if (!projectVersion.matches("^\\d{1,2}\\.\\d{1,2}\\.\\d{1,2}(-SNAPSHOT)?$")) {
            throw new IllegalArgumentException("Illegal value of FTLDB project version: " + projectVersion);
        }

        STRING_VALUE = projectVersion.replaceFirst("-SNAPSHOT", "");

        String[] versionNumbers = STRING_VALUE.split("\\D+");
        int intValue = 0;
        for (int i = 0; i < versionNumbers.length; i++) {
            intValue += Integer.parseInt(versionNumbers[i]) * (int) Math.pow(100, versionNumbers.length - i - 1);
        }

        INT_VALUE = intValue;
    }

    /**
     * Returns the FTLDB version as a String.
     *
     * @return FTLDB version
     */
    public static String getStringValue() {
        return STRING_VALUE;
    }

    /**
     * Returns the FTLDB version as a comparable integer.
     *
     * @return FTLDB version
     */
    public static int getIntValue() {
        return INT_VALUE;
    }

}
