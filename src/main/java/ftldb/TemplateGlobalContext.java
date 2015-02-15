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


import java.util.HashMap;
import java.util.Map;


/**
 * A helper class for storing FTL variables and passing them between different templates. Can be accessed in FTL as
 * a shared variable {@code global_context}.
 */
public class TemplateGlobalContext {

    private final Map storage = new HashMap();


    /**
     * Saves the specified parameter value into the storage.
     *
     * @param parameter the parameter name
     * @param value the parameter value
     */
    public void set(String parameter, Object value) {
        storage.put(parameter, value);
    }


    /**
     * Returns the previously set parameter from the storage. If the parameter is not set, returns null.
     *
     * @param parameter the parameter name
     * @return stored parameter value
     */
    public Object get(String parameter) {
        return storage.get(parameter);
    }


    /**
     * Returns the whole context as a {@link java.util.Map}.
     *
     * @return the inner storage
     */
    public Map get() {
        return storage;
    }


    /**
     * Drops the specified parameter from the storage, if presented.
     *
     * @param parameter the parameter name
     */
    public void clear(String parameter) {
        storage.remove(parameter);
    }


    /**
     * Cleans up the storage.
     */
    public void clear() {
        storage.clear();
    }

}