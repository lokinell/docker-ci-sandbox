#!/bin/sh -e
#
# Initialize OpenLDAP data
#

# Expected environment variables
echo "Test environment configuration..."
[ $(id -u) -eq 0 ]
echo "Succeeded"

chown openldap /var/lib/ldap

[ ! -f /var/lib/ldap/DB_CONFIG ] || exit 0

# The following steps are for initial bootstrapping only

# Create LDAP database
su openldap -s /bin/sh -c "slapadd -v -n 1" <<_DB_INIT
dn: dc=asf,dc=griddynamics,dc=com
objectClass: dcObject
objectClass: organization
o: ASF
dc: asf

dn: cn=admin,dc=asf,dc=griddynamics,dc=com
objectClass: organizationalRole
cn: admin
description: LDAP administrator
_DB_INIT

# Create basic LDAP entities
su openldap -s /bin/sh -c "slapadd -v -n 1" <<_ENTITIES
dn: ou=people,dc=asf,dc=griddynamics,dc=com
objectclass: organizationalUnit
ou: people

dn: ou=groups,dc=asf,dc=griddynamics,dc=com
objectclass: organizationalUnit
ou: groups
_ENTITIES

