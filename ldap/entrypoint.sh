#!/bin/sh -e
#
# Docker container ENTRYPOINT for ldap
# It initializes the LDAP DB (1st time) and run CMD process.
#

[ ! -f /run/lock/initialized ] || exec "$@"


# The following steps are for initial bootstrapping only

# LDAP administrator
ldap_admin_dn="cn=admin,dc=asf,dc=griddynamics,dc=com"

# Expected environment variables
# to be passed from Docker command line or fig.yml:
#
echo "Test environment configuration..."
[ "$ldap_admin_pw" ]
echo "Succeeded"


# Start LDAP daemon listening for local requests only
# then feed it with LDAP data.
#
slapd -u openldap -h "ldapi:///" -F /etc/ldap/slapd.d

# Set password LDAP administrator
#
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<_ADMIN_PASSWORD
dn: olcDatabase={1}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $(slappasswd -s "$ldap_admin_pw")
-
_ADMIN_PASSWORD

# Populate LDAP DB with basic entries.
#
ldapadd -H ldapi:/// -x -D "$ldap_admin_dn" -w "$ldap_admin_pw" <<_ENTITIES
dn: ou=people,dc=asf,dc=griddynamics,dc=com
objectclass: organizationalUnit
ou: people

dn: ou=groups,dc=asf,dc=griddynamics,dc=com
objectclass: organizationalUnit
ou: groups

# System accounts

dn: uid=admin,ou=people,dc=asf,dc=griddynamics,dc=com
objectclass: inetOrgPerson
cn: Administrator
sn: Administrator
displayname: System Administrator
uid: admin
userpassword: $(slappasswd -s "admin")

# TODO: Not sure if Jenkins user has to be an inetOrgPerson in ou=people,
# or not just simpleSecurityObject elsewhere to distinguish from real people.
dn: uid=jenkins-bot,ou=people,dc=asf,dc=griddynamics,dc=com
objectclass: inetOrgPerson
cn: Jenkins CI
sn: Jenkins CI
uid: jenkins-bot
userpassword: $(slappasswd -s "jenkins")

# System groups

dn: cn=admins,ou=groups,dc=asf,dc=griddynamics,dc=com
objectclass: groupOfNames
cn: admins
member: uid=admin,ou=people,dc=asf,dc=griddynamics,dc=com

dn: cn=users,ou=groups,dc=asf,dc=griddynamics,dc=com
objectclass: groupOfNames
cn: users
member: uid=admin,ou=people,dc=asf,dc=griddynamics,dc=com

dn: cn=robots,ou=groups,dc=asf,dc=griddynamics,dc=com
objectclass: groupOfNames
cn: robots
member: uid=jenkins-bot,ou=people,dc=asf,dc=griddynamics,dc=com
_ENTITIES

# Terminate temporary LDAP daemon, wait a bit to let it exit gracefully
killall -w slapd


# Proceed with CMD
touch /run/lock/initialized
exec "$@"

