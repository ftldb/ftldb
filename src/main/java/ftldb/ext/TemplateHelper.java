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


import freemarker.core.Environment;
import freemarker.core.EnvironmentInternalsAccessor;
import freemarker.template.*;

import java.io.IOException;
import java.util.List;
import java.util.Map;


/**
 * This class contains implementation of FTL methods and directives related to templates.
 */
public class TemplateHelper {


    /**
     * This class implements an FTL directive named {@code template} that checks that the template name declared in it
     * coincides with the reference tamplate name passed to the template loader. Otherwise an error is logged to stderr.
     *
     * <p>Directive definition: {@code template(String name)}
     * <p>Method arguments:
     * <pre>
     *     {@code name} - the template name
     * </pre>
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * <@template name = 'ftldb/std.ftl'/>
     * }
     * </pre>
     */
    public static class TemplateDirective implements TemplateDirectiveModel {

        private static final String PARAM_NAME_NAME = "name";

        public void execute(Environment env, Map params, TemplateModel[] loopVars, TemplateDirectiveBody body)
                throws TemplateException, IOException {
            if (body != null) {
                throw new TemplateModelException("Wrong usage: body is not allowed");
            }
            if (loopVars.length != 0) {
                throw new TemplateModelException("Wrong usage: loop variables are not allowed");
            }
            if (params.size() != 1) {
                throw new TemplateModelException("Wrong number of named parameters: expected 1, got " + params.size());
            }
            if (!params.containsKey(PARAM_NAME_NAME)) {
                throw new TemplateModelException("Wrong parameter name:"
                        + " expected \"" + PARAM_NAME_NAME + "\", got \"" + params.keySet().toArray()[0] + "\"");
            }

            Object o = params.get(PARAM_NAME_NAME);
            if (!(o instanceof TemplateScalarModel)) {
                throw new TemplateModelException("Illegal type of parameter \"" + PARAM_NAME_NAME + "\":"
                        + " expected string, got " + o.getClass().getName());
            }
            String declaredName = ((TemplateScalarModel) o).getAsString();

            String referenceName = env.getCurrentTemplate().getName();

            if (referenceName != null && !referenceName.equals(declaredName)) {
                System.err.println("[WARNING] Declared template name \"" + declaredName + "\" does not coincide"
                        + " with reference name \"" + referenceName + "\" passed to template loader.");
            }
        }

    }


    /**
     * This class implements an FTL method named {@code template_name} that returns the current template name. No arguments
     * are needed.
     *
     * <p>Method definition: {@code String template_name()}
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * generated by template "${template_name()}"
     * }
     * </pre>
     */
    public static class TemplateNameMethod implements TemplateMethodModelEx {

        public Object exec(List args) throws TemplateModelException {
            if (args.size() != 0) {
                throw new TemplateModelException("No arguments needed");
            }
            return Environment.getCurrentEnvironment().getCurrentTemplate().getName();
        }

    }


    /**
     * This class implements an FTL method named {@code template_line} that returns the current line number in a template.
     * No arguments are needed.
     *
     * <p>Method definition: {@code int template_line()}
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * current line is ${template_line()}
     * }
     * </pre>
     */
    public static class TemplateLineMethod implements TemplateMethodModelEx {

        public Object exec(List args) throws TemplateModelException {
            if (args.size() != 0) {
                throw new TemplateModelException("No arguments needed");
            }
            return new Integer(EnvironmentInternalsAccessor.getInstructionStackSnapshot()[0].getBeginLine());
        }

    }


}