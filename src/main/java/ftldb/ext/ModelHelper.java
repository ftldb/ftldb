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
package ftldb.ext;


import freemarker.ext.beans.BeansWrapper;
import freemarker.ext.beans.BeansWrapperBuilder;
import freemarker.template.*;
import ftldb.Configurator;

import java.util.*;


/**
 * A helper class for working with FTL models.
 */
public class ModelHelper {


    /**
     * Returns an instance of {@link BeansWrapper}.
     * @return an instance of BeansWrapper
     */
    public static BeansWrapper getBeansWrapper() {
        return new BeansWrapperBuilder(Configurator.getConfiguration().getIncompatibleImprovements()).build();
    }


    /**
     * Converts the specified sequence into a {@link List}.
     *
     * @param seq the sequence to be converted
     * @return a list with the same content
     *
     * @throws TemplateModelException if data cannot be retrieved
     */
    public static List toList(TemplateSequenceModel seq) throws TemplateModelException {
        BeansWrapper bw = getBeansWrapper();
        List list = new ArrayList(seq.size());
        for (int i = 0; i < seq.size(); i++) {
            list.add(bw.unwrap((TemplateModel) seq.get(i)));
        }
        return list;
    }


    /**
     * Converts the specified hash into a {@link Map}.
     *
     * @param hash the hash to be converted
     * @return a map with the same content
     *
     * @throws TemplateModelException if data cannot be retrieved
     */
    public static Map toMap(TemplateHashModelEx hash) throws TemplateModelException {
        BeansWrapper bw = getBeansWrapper();
        Map map = new HashMap(hash.size(), 1);
        TemplateModelIterator it = hash.keys().iterator();
        while (it.hasNext()) {
            String key = ((TemplateScalarModel) it.next()).getAsString();
            map.put(key, bw.unwrap((TemplateModel) hash.get(key)));
        }
        return map;
    }


}