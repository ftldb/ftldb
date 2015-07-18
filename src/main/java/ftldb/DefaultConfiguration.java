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


import freemarker.template.*;
import ftldb.ext.*;
import ftldb.ext.sql.Connector;


/**
 * The default configuration. Supports the latest FreeMarker features. Uses the default object wrapper. Localized lookup
 * is switched off.
 *
 * <p>Registered shared variables and methods are:
 * <ul>
 *     <li>{@code shared_hash} - see {@link SharedHash}
 *     <li>{@code static} - see {@link StaticMethod}
 *     <li>{@code template_name} - see {@link TemplateNameMethod}
 *     <li>{@code template_line} - see {@link TemplateLineMethod}
 *     <li>{@code new_connection} - see {@link ftldb.ext.sql.Connector.NewConnectionMethod}
 *     <li>{@code default_connection} - see {@link ftldb.ext.sql.Connector.GetDefaultConnectionMethod}
 *     <li>{@code set_default_connection} - see {@link ftldb.ext.sql.Connector.SetDefaultConnectionMethod}
 *     <li>{@code shell_exec} - see {@link ftldb.ext.ShellCommandExecutor.ShellExecMethod}
 * </ul>
 */
public class DefaultConfiguration extends Configuration {


    // The currently supported FreeMarker features
    private final static Version FM_INCOMPATIBLE_IMPROVEMENTS = Configuration.VERSION_2_3_23;


    public DefaultConfiguration() {
        super(FM_INCOMPATIBLE_IMPROVEMENTS);

        // Set default settings
        setObjectWrapper(new DefaultObjectWrapperBuilder(FM_INCOMPATIBLE_IMPROVEMENTS).build());
        setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
        setLocalizedLookup(false);

        // Register user-defined variables and methods
        registerUserDefinedVariablesAndMethods();
    }


    protected void registerUserDefinedVariablesAndMethods() {
        try{
            setSharedVariable("shared_hash", new SharedHash());
        } catch(TemplateModelException e){
            throw new RuntimeException("Unable to register \"shared_hash\" variable", e);
        }

        setSharedVariable("static", new StaticMethod());
        setSharedVariable("template_name", new TemplateNameMethod());
        setSharedVariable("template_line", new TemplateLineMethod());
        setSharedVariable("new_connection", new Connector.NewConnectionMethod());
        setSharedVariable("default_connection", new Connector.GetDefaultConnectionMethod());
        setSharedVariable("set_default_connection", new Connector.SetDefaultConnectionMethod());
        setSharedVariable("shell_exec", new ShellCommandExecutor.ShellExecMethod());
    }


}
