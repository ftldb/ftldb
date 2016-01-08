/*
 * Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy
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
package ftldb.ext;


import java.util.HashMap;
import java.util.Map;


/**
 * A helper class for storing FTL variables and passing them between different templates. Can be accessed in FTL as
 * a shared variable named {@code shared_hash}.
 *
 * <p>Usage examples in FTL:
 * <pre>
 * {@code
 * <#assign void = shared_hash.put("a", 1)/>
 * <#assign void = shared_hash.put("b", "text")/>
 * a = ${shared_hash.get("a")?c}
 * <#assign map = shared_hash.get()/>
 * b = ${map["b"]}
 * <#assign void = shared_hash.remove("b")/>
 * <#assign void = shared_hash.clear()/>
 * }
 * </pre>
 */
public class SharedHash {


    private final Map storage = new HashMap();


    /**
     * Saves the specified key value into the storage.
     *
     * @param key the key name
     * @param value the key value
     */
    public void put(String key, Object value) {
        storage.put(key, value);
    }


    /**
     * Returns the previously set key from the storage. If the key is not set, returns null.
     *
     * @param key the key name
     * @return stored key value
     */
    public Object get(String key) {
        return storage.get(key);
    }


    /**
     * Returns the whole storage as a {@link Map}.
     *
     * @return the inner storage
     */
    public Map get() {
        return storage;
    }


    /**
     * Drops the specified key from the storage, if presented.
     *
     * @param key the key name
     */
    public void remove(String key) {
        storage.remove(key);
    }


    /**
     * Cleans up the storage.
     */
    public void clear() {
        storage.clear();
    }


}