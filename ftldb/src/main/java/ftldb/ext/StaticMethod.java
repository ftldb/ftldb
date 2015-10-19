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


import freemarker.ext.beans.BeansWrapperBuilder;
import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModelException;
import freemarker.template.TemplateScalarModel;
import ftldb.Configurator;

import java.util.List;


/**
 * This class implements an FTL method named {@code static} that returns a static model for the specified class.
 *
 * <p>Method definition: {@code StaticModel static(String class_name)}
 * <p>Method arguments:
 * <pre>
 *     {@code class_name} - the name of the class
 * </pre>
 *
 * <p>Usage examples in FTL:
 * <pre>
 * {@code
 * <#assign sqrt2 = static("java.lang.Math").sqrt(2)/>
 * <#assign pi = static("java.lang.Math").PI/>
 * }
 * </pre>
 */
public class StaticMethod implements TemplateMethodModelEx {


    public Object exec(List args) throws TemplateModelException {
        if (args.size() != 1) {
            throw new TemplateModelException("Wrong number of arguments: expected 1, got " + args.size());
        }

        Object classNameObj = args.get(0);
        if (!(classNameObj instanceof TemplateScalarModel)) {
            throw new TemplateModelException("Illegal type of argument #1: "
                    + "expected string, got " + classNameObj.getClass().getName());
        }

        return new BeansWrapperBuilder(Configurator.getConfiguration().getIncompatibleImprovements()).build()
                .getStaticModels().get(((TemplateScalarModel) classNameObj).getAsString());
    }


}
