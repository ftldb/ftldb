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
package ftldb;


import java.io.File;
import java.io.IOException;


/**
 * This class is subclass of {@link freemarker.cache.FileTemplateLoader}. The only difference from the parent is that
 * template names are prefixed with @.
 */
public class FileTemplateLoader extends freemarker.cache.FileTemplateLoader {


    /**
     * @deprecated
     */
    public FileTemplateLoader() throws IOException {
        super();
    }


    public FileTemplateLoader(final File baseDir) throws IOException {
        super(baseDir);
    }


    public FileTemplateLoader(final File baseDir, final boolean disableCanonicalPathCheck) throws IOException {
        super(baseDir, disableCanonicalPathCheck);
    }


    /**
     * Finds a template by its name starting with @. If the name starts with @, the path is absolute.
     * If the name starts with @@, the path is relative to the parent template.
     *
     * @param name the template's name starting with @
     * @return the template storing file
     * @throws IOException if the name does not start with @ or another error occurs
     */
    public Object findTemplateSource(String name) throws IOException {
        if (!name.startsWith("@")) {
            throw new IOException("Template name \"" + name + "\" must start with @");
        }

        return super.findTemplateSource(name.substring(1));
    }


}
