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


import freemarker.cache.TemplateNameFormat;
import freemarker.template.Configuration;
import freemarker.template.TemplateExceptionHandler;
import freemarker.template.TemplateModelException;
import ftldb.ext.*;
import ftldb.ext.sql.Connector;


/**
 * The default configuration. Supports the latest FreeMarker features. Uses the FTLDB's default object wrapper, which
 * extends FreeMarker's with SQL type wrapping. Localized lookup is switched off. FTL exceptions are simply rethrown.
 *
 * <p>Registered shared variables and methods are:
 * <ul>
 *     <li>{@code shared_hash} - see {@link SharedHash}
 *     <li>{@code static} - see {@link StaticMethod}
 *     <li>{@code template} - see {@link ftldb.ext.TemplateHelper.TemplateDirective}
 *     <li>{@code template_name} - see {@link ftldb.ext.TemplateHelper.TemplateNameMethod}
 *     <li>{@code template_line} - see {@link ftldb.ext.TemplateHelper.TemplateLineMethod}
 *     <li>{@code new_connection} - see {@link ftldb.ext.sql.Connector.NewConnectionMethod}
 *     <li>{@code default_connection} - see {@link ftldb.ext.sql.Connector.GetDefaultConnectionMethod}
 *     <li>{@code set_default_connection} - see {@link ftldb.ext.sql.Connector.SetDefaultConnectionDirective}
 *     <li>{@code shell_exec} - see {@link ftldb.ext.ShellCommandExecutor.ShellExecMethod}
 * </ul>
 */
public class DefaultConfiguration extends Configuration {


    public DefaultConfiguration() {
        // Set FreeMarker features up to the latest version
        super(getVersion());

        // Set default settings
        setObjectWrapper(new DefaultObjectWrapper(this.getIncompatibleImprovements()));
        setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
        setLocalizedLookup(false);
        setTemplateNameFormat(TemplateNameFormat.FTLDB_NAME_FORMAT);

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
        setSharedVariable("template", new TemplateHelper.TemplateDirective());
        setSharedVariable("template_name", new TemplateHelper.TemplateNameMethod());
        setSharedVariable("template_dirname", new TemplateHelper.TemplateDirnameMethod());
        setSharedVariable("template_line", new TemplateHelper.TemplateLineMethod());
        setSharedVariable("new_connection", new Connector.NewConnectionMethod());
        setSharedVariable("default_connection", new Connector.GetDefaultConnectionMethod());
        setSharedVariable("set_default_connection", new Connector.SetDefaultConnectionDirective());
        setSharedVariable("shell_exec", new ShellCommandExecutor.ShellExecMethod());
    }


}
