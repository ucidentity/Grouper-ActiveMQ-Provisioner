# AD/LDAP ActiveMQ Grouper Provisioner


### Features
The AD/LDAP ActiveMQ Grouper provisioner has the following features:

* Supports multiple provisioner instances/configurations.
* Fine-grain control over which groups are provisioned.
* Support of blocking group provisioning where group has more than X members.
* Utilizes ActiveMQ queues to support individual service provisioning.
* Supports AD, LDAP groups, and LDAP IsMemberOf provisioning.
* Includes support for renaming groups (wasn't included in original code base).



### Instructions

#### Change Log Consumer
Add the change log consumer jar file to lib/custom along with other jar files from lib. Alternately, they can exist in their own directory if added to the class path.

Add configuration info to grouper-loader.properties file.
````
changeLog.consumer.ldapIMO.class = edu.cmu.grouper.changelog.consumer.ConsumerMain
changeLog.consumer.ldapIMO.quartzCron = 0 * * * * ?
> #changeLog.consumer.ldapIMO.targets=dev.grouper.changelog.ldapGroup
changeLog.consumer.ldapIMO.targets=dev.ldap.isMemberOf
changeLog.consumer.ldapIMO.isMemberOfQueue=test.389.groups
changeLog.consumer.ldapIMO.usduExcludes=Apps:OIM-DEV02:exchange,Apps:OIM-DEV02:activeDirectory
changeLog.consumer.ldapIMO.brokerURL=failover:(ssl://amq-t1.calnet.1918.berkeley.edu:61617,ssl://amq-t1.calnet.1918.berkeley.edu:61617)?randomize=false
changeLog.consumer.ldapIMO.username=grouper
changeLog.consumer.ldapIMO.password=
changeLog.consumer.ldapIMO.maxMembers=1000
changeLog.consumer.ldapIMO.syncAttribute=etc:attribute:provisioningTargets:all:syncToLdap
changeLog.consumer.ldapIMO.allowLargeGroupsAttribute=etc:attribute:provisioningTargets:all:allowLargeGroups
# syncType is either basic or isMemberOf, default is basic
changeLog.consumer.ldapIMO.syncType=isMemberOf
# useXmlMessageFormat is true or false, default is true
changeLog.consumer.ldapIMO.useXmlMessageFormat=false
````

Setup ActiveMQ queues. You will need a separate queue for each service (AD, LDAP, LDAP IsMemberOf, other service). We are currently supporting AD and LDAP IsMemberOf (berkeleyEduIsMemberOf). 

#### AD/LDAP/IsMemberOf Provisioning
Setup separate directories for each downstream component. For example, AD, LDAP, LDAP IsMemberOf. Setup configuration files to connect with downstream servers and appropriate ActiveMQ queues. 



### Acknowledgements
Carnegie Melon for original code base.