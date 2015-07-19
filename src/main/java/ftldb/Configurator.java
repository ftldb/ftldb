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


import freemarker.template.Configuration;
import freemarker.template.TemplateException;
import freemarker.template.Version;

import java.beans.XMLDecoder;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;


/**
 * This class sets up the FreeMarker configuration as a singleton.
 */
public class Configurator {


    // The current configuration.
    private static Configuration config;


    /**
     * Getter for the inner {@link Configuration} static field.
     *
     * @return the current configuration
     */
    public static synchronized Configuration getConfiguration() {
        ensureConfigurationIsSet();
        return config;
    }


    /**
     * Setter for the inner {@link Configuration} static field.
     *
     * @param config the new configuration
     */
    public static synchronized void setConfiguration(Configuration config) {
        Configurator.config = config;
    }


    /**
     * Creates a new {@link Configuration} instance from a JavaBean serialized with {@link java.beans.XMLEncoder}.
     *
     * @param configXMLInputStream XML binary stream
     */
    public static Configuration newConfiguration(InputStream configXMLInputStream) {
        XMLDecoder decoder = new XMLDecoder(configXMLInputStream);
        Configuration config = (Configuration) decoder.readObject();
        decoder.close();
        return config;
    }


    /**
     * Instantiates a new {@link Configuration} object from a JavaBean serialized with {@link java.beans.XMLEncoder} and
     * sets it as the current configuration.
     *
     * @param configXMLInputStream the new configuration as an XML binary stream
     */
    public static void setConfiguration(InputStream configXMLInputStream) {
        setConfiguration(newConfiguration(configXMLInputStream));
    }


    /**
     * The convenience method for {@link #setConfiguration(InputStream)}.
     *
     * @param configXMLString the new configuration as an XML string
     */
    public static void setConfiguration(String configXMLString) {
        setConfiguration(new ByteArrayInputStream(configXMLString.getBytes()));
    }


    /**
     * Sets the specified setting in the current configuration with the specified value.
     *
     * @param name the setting name
     * @param value the setting value
     * @throws TemplateException if cannot set the setting
     */
    public static synchronized void setConfigurationSetting(String name, String value) throws TemplateException {
        ensureConfigurationIsSet();
        config.setSetting(name, value);
    }


    /**
     * Drops the current configuration. In order to continue, the configuration must be re-set.
     */
    public static synchronized void dropConfiguration() {
        config = null;
    }


    private static void ensureConfigurationIsSet() {
        if (config == null) {
            throw new RuntimeException("FTLDB configuration is not initialized");
        }
    }


    private static final String VERSION_PROPERTY_PATH = "ftldb/version.properties";
    private static final String VERSION_PROPERTY_NAME = "version";
    private static Version VERSION;


    /**
     * Returns FTLDB version as a {@link Version} instance.
     *
     * @return FTLDB version
     */
    public static Version getVersion() {
        if (VERSION == null) {
            VERSION = readVersion();
        }
        return VERSION;
    }


    private static Version readVersion() {
        try {
            Properties vp = new Properties();
            InputStream ins = Configurator.class.getClassLoader().getResourceAsStream(VERSION_PROPERTY_PATH);
            if (ins == null) {
                throw new RuntimeException("FTLDB version file is missing: " + VERSION_PROPERTY_PATH);
            } else {
                try {
                    vp.load(ins);
                } finally {
                    ins.close();
                }

                String versionString = vp.getProperty(VERSION_PROPERTY_NAME);
                if (versionString == null) {
                    throw new RuntimeException("FTLDB version file is corrupt: \"" + VERSION_PROPERTY_NAME
                            + "\" property is missing.");
                }

                return new Version(versionString);
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to load and parse " + VERSION_PROPERTY_PATH, e);
        }
    }


}
