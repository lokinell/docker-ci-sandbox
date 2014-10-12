#!/bin/sh -e
#
# Initialize OpenLDAP data
#

# Expected environment variables
echo "Test environment configuration..."
[ $(id -u) -eq 0 ]
echo "Succeeded"

[ ! -f /var/lib/ldap/DB_CONFIG ] || exit 0

# The following steps are for initial bootstrapping only

bind_dn="cn=admin,dc=asf,dc=griddynamics,dc=com"
bind_pass="admin"

chown openldap /var/lib/ldap

# Create LDAP database
su openldap -s /bin/sh -c "slapadd -v -n 1" <<_DB_INIT
dn: dc=asf,dc=griddynamics,dc=com
objectClass: dcObject
objectClass: organization
o: ASF
dc: asf
_DB_INIT

# Populate LDAP DB with basic entries.
#
# Start LDAP daemon listening for local requests only
# then feed it with LDAP data.
slapd -u openldap -h "ldapi:///" -F /etc/ldap/slapd.d

pass=`slappasswd -s "admin"`

ldapadd -H ldapi:/// -x -D "$bind_dn" -w "$bind_pass" <<_ENTITIES
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
userpassword: ${pass}

# TODO: Not sure if Jenkins user has to be an inetOrgPerson in ou=people,
# or not just simpleSecurityObject elsewhere to distinguish from real people.
dn: uid=jenkins-bot,ou=people,dc=asf,dc=griddynamics,dc=com
objectclass: inetOrgPerson
cn: Jenkins CI
sn: Jenkins CI
uid: jenkins-bot

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

