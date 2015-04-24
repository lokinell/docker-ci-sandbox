# ldap
#
# OpenLDAP server
#
# Documentation:
#  - https://help.ubuntu.com/12.04/serverguide/openldap-server.html

FROM ci-base:centos
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 389

RUN yum -y install openldap-clients openldap-servers

# entrypoint script handles DB initialization
COPY entrypoint.sh /entrypoint
RUN chmod 700 /entrypoint

# LDAP configuration parameters
ENV organization ASF

ENTRYPOINT ["/entrypoint"]
CMD ["slapd", "-u", "ldap", "-h", "ldap:/// ldapi:///", "-F", "/etc/openldap/slapd.d", "-d", "Stats"]

