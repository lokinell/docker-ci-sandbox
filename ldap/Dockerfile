# ldap
#
# OpenLDAP server
#
# Documentation:
#  - https://help.ubuntu.com/12.04/serverguide/openldap-server.html

FROM ci-base:ubuntu
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 389

# Pre-set configuration parameters for OpenLDAP server (slapd)
RUN pass="admin" \
    && ( \
        echo "slapd	slapd/domain	string	asf.griddynamics.com"; \
        echo "slapd	shared/organization	string	ASF"; \
        echo "slapd	slapd/password1	password	$pass"; \
        echo "slapd	slapd/password2	password	$pass"; \
    ) | debconf-set-selections

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -qy install ldap-utils slapd

# entrypoint script handles DB initialization
COPY entrypoint.sh /entrypoint
RUN chmod 700 /entrypoint

ENTRYPOINT ["/entrypoint"]
CMD ["slapd", "-u", "openldap", "-h", "ldap:/// ldapi:///", "-F", "/etc/ldap/slapd.d", "-d", "Stats"]

