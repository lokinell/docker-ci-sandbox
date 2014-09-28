# ldap
#
# OpenLDAP server
#
# Documentation:
#  - https://help.ubuntu.com/12.04/serverguide/openldap-server.html
#  - https://help.ubuntu.com/community/InstallingphpLDAPadmin

FROM ubuntu:12.04
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 389

# Install OpenLDAP with a trick to set root domain to "asf.griddynamics.com" 
RUN cp /etc/hosts /etc/hosts.save \
    && awk -vh=`hostname` -vd=asf.griddynamics.com \
        '$2==h {print $1, $2 "." d, $2 ; next} {print $0}' \
        </etc/hosts.save >/etc/hosts \
    && apt-get -q update && apt-get -qy install slapd ldap-utils \
    && cp /etc/hosts.save /etc/hosts && rm /etc/hosts.save

# Set admin password to "admin"
RUN service slapd start \
    && pass=`slappasswd -s "admin"` \
    && ( \
        echo "dn: olcDatabase={1}hdb,cn=config"; \
        echo "changetype: modify"; \
        echo "replace: olcRootPW"; \
        echo "olcRootPW: $pass"; \
        echo "-" \
    ) | ldapmodify -Y EXTERNAL -H ldapi:/// \
    && killall slapd

CMD ["slapd", "-u", "openldap", "-h", "ldap:/// ldapi:///", "-F", "/etc/ldap/slapd.d", "-d", "Stats"]

