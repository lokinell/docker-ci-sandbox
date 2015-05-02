# ldapAdmin
#
# Web UI for LDAP server
#

FROM ci-base:centos
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 80

RUN yum -y install phpldapadmin

COPY phpldapadmin/config.php /etc/phpldapadmin/
COPY httpd/* /etc/httpd/conf.d/
RUN chgrp apache /etc/phpldapadmin/config.php /etc/httpd/conf.d/*.conf \
    && chmod 640 /etc/phpldapadmin/config.php /etc/httpd/conf.d/*.conf


CMD ["apachectl", "-k", "start", "-DFOREGROUND"]

