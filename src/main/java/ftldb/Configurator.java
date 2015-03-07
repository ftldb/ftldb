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


import freemarker.cache.*;
import freemarker.core.Environment;
import freemarker.core._CoreAPI;
import freemarker.ext.beans.BeansWrapper;
import freemarker.template.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;


/**
 * This class sets up the FreeMarker configuration and registers shared variables and methods for working in FTL.
 */
public class Configurator {

    /** The currently supported version of FreeMarker */
    public final static Version SUPPORTED_VERSION = Configuration.VERSION_2_3_21;
    private static Configuration cfg;


    /**
     * Drops the current configuration. In order to continue using FTL, the configuration must be re-set.
     * This method is a part of FTLDB API for PL/SQL.
     */
    public static synchronized void dropConfiguration() {
        cfg = null;
    }


    /**
     * Checks if the configuration is set up and returns it.
     *
     * @return the current configuration
     */
    public static Configuration getConfiguration() {
        ensureCfg();
        return cfg;
    }


    /**
     * Sets the new configuration. Registers new methods and variables available in FTL.
     *
     * <p>This method is a part of FTLDB API for PL/SQL.
     *
     * <p>Available shared variables and methods are:
     * <ul>
     *     <li>{@code global_context} is an instance of {@link TemplateGlobalContext}
     *     <li>{@code static(String)} returns the static model of a class, which allows to call any of its static
     *         methods
     *     <li>{@code template_line()} returns the current line in a template
     *     <li>{@code new_connection(String, String, String)} opens and returns a new connection to a database with
     *         the specified url, name and password
     *     <li>{@code new_connection()} opens and returns a new connection to a database with "jdbc:default:connection"
     *         url
     *     <li>{@code default_connection()} returns the default connection set for the configuration
     *     <li>{@code set_default_connection(DBConnection)} overrides the default connection
     * </ul>
     *
     * <p>Usage examples in FTL:
     * <pre>
     * {@code
     * <#assign void = global_context.set("a", 2)/>
     * a = ${global_context.get("a")}
     *
     * <#assign sqr2 = static("java.lang.Math").sqrt(2)/>
     *
     * current line is ${template_line()}
     *
     * <#assign inner_conn = new_connection()/>
     * <#assign ext_conn = new_connection("jdbc:oracle:thin@//localhost:1521/orcl", "scott", "tiger")/>
     * <#assign void = set_default_connection(ext_conn)/>
     * <#assign def_conn = default_connection()/>
     * }
     * </pre>
     */
    public static synchronized void newConfiguration() {
        cfg = new Configuration(SUPPORTED_VERSION);

        cfg.setObjectWrapper(new DefaultObjectWrapperBuilder(SUPPORTED_VERSION).build());
        cfg.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
        cfg.setLocalizedLookup(false);

        // Register shared variables.
        registerGlobalContextSharedVariable();

        // Register shared methods.
        registerStaticSharedMethod();
        registerTemplateLineSharedMethod();
        registerDBConnectionSharedMethods();
    }


    private static void registerGlobalContextSharedVariable() {
        try {
            cfg.setSharedVariable("global_context", new TemplateGlobalContext());
        } catch (TemplateModelException e) {
            throw new RuntimeException("Unable to set global_context", e);
        }
    }


    private static void registerStaticSharedMethod() {
        cfg.setSharedVariable("static", new TemplateMethodModelEx() {
            public Object exec(List args) throws TemplateModelException {
                if (args.size() != 1) throw new TemplateModelException("One argument expected, got " + args.size());
                String className = ((SimpleScalar) args.get(0)).getAsString();
                return ((BeansWrapper) cfg.getObjectWrapper()).getStaticModels().get(className);
            }
        });
    }


    private static void registerTemplateLineSharedMethod() {
        cfg.setSharedVariable("template_line", new TemplateMethodModelEx() {
            public Object exec(List args) throws TemplateModelException {
                if (args.size() != 0) throw new TemplateModelException("No arguments needed");
                return new Integer(
                        _CoreAPI.getInstructionStackSnapshot(Environment.getCurrentEnvironment())[0].getBeginLine()
                );
            }
        });
    }


    private static void registerDBConnectionSharedMethods() {
        DBConnectionFactory dbcf = new DBConnectionFactory();
        cfg.setSharedVariable("new_connection", dbcf.getMethodNewDBConnection());
        cfg.setSharedVariable("default_connection", dbcf.getMethodGetDefaultDBConnection());
        cfg.setSharedVariable("set_default_connection", dbcf.getMethodSetDefaultDBConnection());
    }


    /**
     * Sets the template loader for the current configuration.
     *
     * @param templateLoader the template loader
     * @param cacheStorage the cache storage
     */
    public static synchronized void setTemplateLoader(TemplateLoader templateLoader, CacheStorage cacheStorage) {
        ensureCfg();
        cfg.setTemplateLoader(templateLoader);
        cfg.setCacheStorage(cacheStorage);
    }


    /**
     * Sets the specified setting in the current configuration with the specified value.
     *
     * <p>This method is a part of FTLDB API for PL/SQL.
     *
     * @param name the setting name
     * @param value the setting value
     * @throws TemplateException if cannot set the setting
     */
    public static synchronized void setConfigurationSetting(String name, String value) throws TemplateException {
        ensureCfg();
        cfg.setSetting(name, value);
    }


    /**
     * Creates a new {@code DBTemplateLoader} instance using the database's inner JDBC connection and sets it as
     * the template loader for the current configuration. The template caching is not used.
     *
     * <p>This method is a part of FTLDB API for PL/SQL.
     *
     * @param call a proper call to the database that returns a template source
     * @throws SQLException if a database access error occurs
     */
    public static void setDBTemplateLoader(String call) throws SQLException {
        Connection conn = DriverManager.getConnection("jdbc:default:connection");
        StatefulTemplateLoader templateLoader = DBTemplateLoaderFactory.newDBTemplateLoader(conn, call);
        Configurator.setTemplateLoader(templateLoader, new NullCacheStorage());
    }


    /**
     * Creates a new {@link FileTemplateLoader} instance and sets it as the template loader for the current
     * configuration. The template caching is not used.
     */
    public static void setDefaultFileTemplateLoader() {
        FileTemplateLoader fileTemplateLoader;
        try {
            fileTemplateLoader = new FileTemplateLoader();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        Configurator.setTemplateLoader(fileTemplateLoader, new SoftCacheStorage());
    }


    private static void ensureCfg() {
        if (cfg == null) {
            throw new RuntimeException("FreeMarker configuration is not initialized");
        }
    }

}
