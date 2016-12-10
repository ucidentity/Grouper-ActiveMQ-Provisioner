FROM centos:centos7

RUN yum -y install epel-release \
    && yum -y update \
    && yum -y install perl perl-JSON perl-Log-Log4perl perl-Net-DNS perl-LDAP\
    && yum -y clean all

COPY temp/amq_ldap_provisioner/ /opt/amq_ldap_provisioner/
COPY configuration.pl /opt/amq_ldap_provisioner/

WORKDIR /opt/amq_ldap_provisioner

CMD perl main.pl
