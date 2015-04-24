#!/bin/sh -e
#
# Docker container ENTRYPOINT for ldap
# It initializes the LDAP DB (1st time) and run CMD process.
#

[ ! -f /var/lock/initialized ] || exec "$@"


# The following steps are for initial bootstrapping only

# LDAP administrator
admin_user="admin"

# Expected environment variables
# to be passed from Docker command line or fig.yml:
#
echo "Test environment configuration..."
[ "$domain" ]
[ "$organization" ]
[ "$admin_user" ]
[ "$ldap_admin_password" ]
[ "$system_admin_password" ]
[ "$jenkins_bot_password" ]
echo "Succeeded"

ldap_domain_name=$(echo "$domain" | cut -f1 -d.)
ldap_domain_dn=$(echo ".${domain}" | sed 's/\./,dc=/g;s/^,//')
ldap_admin_dn="cn=${admin_user},${ldap_domain_dn}"


# Start LDAP daemon listening for local requests only
# then feed it with LDAP data.
#
slapd -u ldap -h "ldapi:///" -F /etc/openldap/slapd.d

# Set password for LDAP administrator
#
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<_ADMIN_PASSWORD
dn: olcDatabase={0}config,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $(slappasswd -s "$ldap_admin_password")
-
_ADMIN_PASSWORD

# Set up the domain
#
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<_LDAP_DOMAIN
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to *
  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read
  by dn.base="${ldap_admin_dn}" read
  by * none

dn: olcDatabase={2}bdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: ${ldap_domain_dn}
-
replace: olcRootDN
olcRootDN: ${ldap_admin_dn}
-
add: olcRootPW
olcRootPW: $(slappasswd -s "$ldap_admin_password")
-
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange
  by dn="${ldap_admin_dn}" write
  by anonymous auth
  by self write
  by * none
olcAccess: {1}to dn.base=""
  by * read
olcAccess: {2}to *
  by dn="${ldap_admin_dn}" write
  by * read
-
_LDAP_DOMAIN

# Populate LDAP DB with basic entries.
#
ldapadd -H ldapi:/// -x -D "$ldap_admin_dn" -w "$ldap_admin_password" <<_ENTITIES
dn: ${ldap_domain_dn}
objectClass: top
objectClass: dcObject
objectclass: organization
o: ${organization}
dc: ${ldap_domain_name}

dn: ou=people,${ldap_domain_dn}
objectclass: organizationalUnit
ou: people

dn: ou=groups,${ldap_domain_dn}
objectclass: organizationalUnit
ou: groups

# System accounts

dn: uid=admin,ou=people,${ldap_domain_dn}
objectclass: inetOrgPerson
cn: Administrator
sn: Administrator
displayname: System Administrator
uid: admin
userpassword: $(slappasswd -s "$system_admin_password")

# TODO: Not sure if Jenkins user has to be an inetOrgPerson in ou=people,
# or not just simpleSecurityObject elsewhere to distinguish from real people.
dn: uid=jenkins-bot,ou=people,${ldap_domain_dn}
objectclass: inetOrgPerson
cn: Jenkins CI
sn: Jenkins CI
uid: jenkins-bot
userpassword: $(slappasswd -s "$jenkins_bot_password")

# System groups

dn: cn=admins,ou=groups,${ldap_domain_dn}
objectclass: groupOfNames
cn: admins
member: uid=admin,ou=people,${ldap_domain_dn}

dn: cn=users,ou=groups,${ldap_domain_dn}
objectclass: groupOfNames
cn: users
member: uid=admin,ou=people,${ldap_domain_dn}

dn: cn=robots,ou=groups,${ldap_domain_dn}
objectclass: groupOfNames
cn: robots
member: uid=jenkins-bot,ou=people,${ldap_domain_dn}
_ENTITIES

# Terminate temporary LDAP daemon, wait a bit to let it exit gracefully
killall -w slapd


# Proceed with CMD
touch /var/lock/initialized
exec "$@"

