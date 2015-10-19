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


import freemarker.cache.ClassTemplateLoader;
import java.io.IOException;


/**
 * This class finds, checks and loads templates stored in Java resources accessible within CLASSPATH.
 */
public class ResourceTemplateLoader extends ClassTemplateLoader {


    public ResourceTemplateLoader() {
        super(ResourceTemplateLoader.class, "/");
    }


    /**
     * Finds a template by its name starting with @. If the name starts with @, the path is absolute within CLASSPATH.
     * If the name starts with @@, the path is relative to the parent template.
     *
     * @param name the template's name starting with @
     * @return the full resource name
     * @throws IOException if the name does not start with @ or another error occurs
     */
    public Object findTemplateSource(String name) throws IOException {
        if (!name.startsWith("@")) {
            throw new IOException("Template name \"" + name + "\" must start with @");
        }

        return super.findTemplateSource(name.substring(1));
    }


}
