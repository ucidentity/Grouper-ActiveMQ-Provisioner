/*Copyright 2014 Carnegie Mellon University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/

package edu.cmu.grouper.changelog.consumer;

import java.lang.Exception;
import java.net.URL;
import java.util.Properties;


import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * Act on member changes
 */
public class ConsumerProperties {

	private final static Log log = LogFactory.getLog(edu.cmu.grouper.changelog.consumer.ConsumerMain.class);

	// the config file name
	private static String configFile = "cmuconsumer.properties";
	
	// indicates if we attempted to read the properties files
	private static boolean didReadProperties = false;
	
	// indicates if we read all required properties from the file
	private static boolean haveRequiredProperties = false;

	
	private static String brokerURL = null;
	private static String username = null;
	private static String password = null;
	private static String targets = null;
	private static String usduExcludes = null;
	private static String exceptionStemsConfig = null;
	private static int maxMembers = 0;

	
	public static boolean propertiesOk() {
		readProperties();
		return haveRequiredProperties;
	}

	public static String getBrokerUrl() {
		readProperties();
		return brokerURL;
	}

	public static String getUsername() {
		readProperties();
		return username;
	}

	public static String getPassword() {
		readProperties();
		return password;
	}
	
	public static String getTargets() {
		readProperties();
		return targets;
	}
	
	public static String getUsduExcludes() {
		readProperties();
		return usduExcludes;
	}
	
	public static String[] getExceptionStems() {
			String delims = "[,]";

		readProperties();
		// check for no stems
		if (exceptionStemsConfig == null) {
			log.warn ("no exception stems");
			return null;
		} else {
			// Split multiple stems into array
			String[] exceptionStems = exceptionStemsConfig.split( delims );
			// Remove * if added
			for ( int i=0; i< exceptionStems.length; i++ ) { 
				if (exceptionStems[i].endsWith("*")) {
					exceptionStems[i] = exceptionStems[i].substring(0, exceptionStems.length - 1);
				}
			}
		       return exceptionStems;
		}		
	}
	

	public static int getMaxMembers() {
		readProperties();
		return maxMembers;
	}

	
	private static void readProperties() {

		// the properties file is only read for the first call
		if (didReadProperties) {
			return;
		}

		didReadProperties = true;
		haveRequiredProperties = false;

		try {
			URL configURL;
			Properties configValues;
			
			configURL = ConsumerProperties.class.getClassLoader().getResource(
					configFile);
			
			
			
			if (configURL == null) {
				log.error("CmuConsumer config file \"" + configFile
						+ "\" not found");
				return;
			}
			
			configValues = new Properties();
			configValues.load(configURL.openStream());
			
			haveRequiredProperties = true;

			brokerURL = configValues.getProperty("brokerURL");
			if (brokerURL == null) {
				haveRequiredProperties = false;
				log.error("brokerURL not found in properties file");
			}

			username = configValues.getProperty("username");
			if (username == null) {
				haveRequiredProperties = false;
				log.error("username not found in properties file");
			}

			password = configValues.getProperty("password");
			if (password == null) {
				haveRequiredProperties = false;
				log.error("password not found in properties file");
			}
			
			targets = configValues.getProperty("targets");
			if (targets == null) {
				haveRequiredProperties = false;
				log.error("targets not found in properties file");
			}
			
			usduExcludes = configValues.getProperty("usduExcludes");
			
			exceptionStemsConfig = configValues.getProperty("exceptionStems");
			if (exceptionStemsConfig == null) {
                                log.error("exceptionStems not found in properties file");
                        }

			if (configValues.getProperty("maxMembers") == null) {
				maxMembers = -1;
                                log.error("maxMembers not found in properties file. Seting to infinite or -1.");
			} else {
			 	maxMembers = Integer.parseInt(configValues.getProperty("maxMembers"));
			        log.debug("maxMembers is: "  maxMembers);
            }
						
			log.info("Read ConsumerProperties config file \"" + configURL + "\" successfully");

		} catch (Exception e) {
			haveRequiredProperties = false;
			log.error("Error reading " + configFile + ": " + e);
		}
	}
	
}
