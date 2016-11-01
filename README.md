# AD/LDAP ActiveMQ Grouper Provisioner
#     (code base is from CMU)


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

Setup ActiveMQ queues. You will need a separate queue for each service (AD, LDAP, LDAP IsMemberOf, other service). We are currently supporting AD and LDAP IsMemberOf (berkeleyEduIsMemberOf). 

#### AD/LDAP/IsMemberOf Provisioning
Setup separate directories for each downstream component. For example, AD, LDAP, LDAP IsMemberOf. Setup configuration files to connect with downstream servers and appropriate ActiveMQ queues. 



### Acknowledgements
Carnegie Melon for original code base.