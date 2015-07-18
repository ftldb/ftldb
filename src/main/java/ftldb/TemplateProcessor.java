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


import freemarker.template.SimpleHash;
import freemarker.template.Template;
import freemarker.template.TemplateException;
import freemarker.template.TemplateModelException;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;


/**
 * This class contains convenience methods for processing templates within the previously set configuration.
 */
public class TemplateProcessor {


    /**
     * Processes a template specified by its name.
     *
     * @param templateName the template's name
     * @param dest the output destination
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    public static void process(String templateName, Writer dest) throws IOException, TemplateException {
        process(getTemplate(templateName), dest);
    }


    /**
     * Processes a template represented as a {@link Reader} stream.
     *
     * @param templateBody the template's source
     * @param dest the output destination
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    public static void process(Reader templateBody, Writer dest) throws IOException, TemplateException {
        process(getTemplate(templateBody), dest);
    }


    /**
     * Adds the specified array to the current configuration as a sequence named {@code template_args}.
     *
     * @param templateArgs an array of template arguments
     * @throws TemplateModelException if a configuration error occurs
     */
    public static void setArguments(String[] templateArgs) throws TemplateModelException {
        Configurator.getConfiguration().setSharedVariable("template_args", templateArgs);
    }


    /**
     * Processes a template represented as a {@link Template} instance.
     *
     * @param template a template object
     * @param dest the output destination
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    protected static void process(Template template, Writer dest) throws IOException, TemplateException {
        SimpleHash root = new SimpleHash(Configurator.getConfiguration().getObjectWrapper());
        template.process(root, dest);
    }


    /**
     * Loads a template by its name and returns it as a {@link Template} instance .
     *
     * @param templateName the template's name
     * @return the template itself
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    protected static Template getTemplate(String templateName) throws IOException, TemplateException {
        if (templateName == null || "".equals(templateName.trim())) {
            throw new IllegalArgumentException("Template name is not specified");
        }
        return Configurator.getConfiguration().getTemplate(templateName);
    }


    /**
     * Wraps a template represented as a {@link Reader} stream into a {@link Template} instance.
     *
     * @param templateBody the template's source
     * @return the template itself
     * @throws IOException if a file access error occurs
     * @throws TemplateException if a template processing error occurs
     */
    protected static Template getTemplate(Reader templateBody) throws IOException, TemplateException {
        if (templateBody == null) {
            throw new IllegalArgumentException("Template body is null");
        }
        return new Template(null, templateBody, Configurator.getConfiguration());
    }


}
