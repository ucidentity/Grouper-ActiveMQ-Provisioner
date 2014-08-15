Typical setup 

Typical Directory Structure:

/opt/grouperDispatcher/       the grouperDispatcher.jar goes in this directory

Log files here -->
/opt/grouperDispatcher/logs/

Config and Properties files here -->
/opt/grouperDispatcher/conf/


Files to customize:

/src/main/java/edu/cmu/is/grouper/dispatcher/Constants.java   (location of grouperDispatcher.properties file, Configuration file etc.

/src/main/resources/grouperDispatcher.properties   (copy this file to the location identified in Constants.java) and update the values of the properties.

/src/main/resources/grouperDispatcherConfig.txt   (copy this configuration file to the location identified in Constants.java) and add your configuration entries 

/src/main/resources/log4j.xml  -- add / modify logging configuration.



