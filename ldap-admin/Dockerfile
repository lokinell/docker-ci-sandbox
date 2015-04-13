# ldapAdmin
#
# Web UI for LDAP server
#
# Documentation:
#  - https://help.ubuntu.com/community/InstallingphpLDAPadmin

FROM ci-base:ubuntu
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 80

RUN apt-get -qy install phpldapadmin

COPY phpldapadmin/config.php /etc/phpldapadmin/
RUN chgrp www-data /etc/phpldapadmin/config.php

RUN echo "ServerName localhost" >/etc/apache2/conf.d/fqdn \
    && echo "ErrorLog |cat" >/etc/apache2/conf.d/console

CMD ["apachectl", "-k", "start", "-DFOREGROUND"]

