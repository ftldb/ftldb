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


import freemarker.core.Environment;
import freemarker.template.Configuration;
import freemarker.template.SimpleHash;
import freemarker.template.Template;
import freemarker.template.TemplateException;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;


/**
 * This class processes templates within the previously set configuration.
 */
public class TemplateProcessor {

    /**
     * Processes the template specified by name.
     *
     * @param templateName the template name
     * @param dest the output destination
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    public static void process(String templateName, Writer dest) throws IOException, TemplateException {
        Configuration cfg = Configurator.getConfiguration();
        if (templateName == null) {
            throw new TemplateException("Template name is not specified", Environment.getCurrentEnvironment());
        }
        SimpleHash root = new SimpleHash(cfg.getObjectWrapper());
        Template temp = cfg.getTemplate(templateName);
        temp.process(root, dest);
    }


    /**
     * Processes the specified template.
     *
     * @param templateBody the template source
     * @param dest the output destination
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    public static void processBody(Reader templateBody, Writer dest) throws IOException, TemplateException {
        Configuration cfg = Configurator.getConfiguration();
        SimpleHash root = new SimpleHash(cfg.getObjectWrapper());
        Template temp = new Template(null, templateBody, cfg);
        temp.process(root, dest);
    }

}
