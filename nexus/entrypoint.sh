#!/bin/sh -e
#
# Docker container ENTRYPOINT for nexus
#

[ ! -f /var/lock/initialized ] || exec "$@"


# The following steps are for initial bootstrapping only

workdir=$(pwd)

# Expected environment variables
# to be passed from Docker command line or fig.yml:
#
echo "Test environment configuration..."
[ "$ldap_admin_password" ]
echo "Succeeded"

cd ../sonatype-work

mkdir -p nexus/conf
cd nexus

save_umask=$(umask)
umask 0077

# LDAP server connection
cat >conf/ldap.xml <<_LDAP_XML
<?xml version="1.0" encoding="UTF-8"?>
<ldapConfiguration>
  <version>2.8.0</version>
  <connectionInfo>
    <searchBase>dc=datarx,dc=cn</searchBase>
    <systemUsername>cn=admin,dc=datarx,dc=cn</systemUsername>
    <systemPassword>${ldap_admin_password}</systemPassword>
    <authScheme>simple</authScheme>
    <protocol>ldap</protocol>
    <host>ldap</host>
    <port>389</port>
  </connectionInfo>
  <userAndGroupConfig>
    <emailAddressAttribute>mail</emailAddressAttribute>
    <ldapGroupsAsRoles>true</ldapGroupsAsRoles>
    <groupBaseDn>ou=groups</groupBaseDn>
    <groupIdAttribute>cn</groupIdAttribute>
    <groupMemberAttribute>member</groupMemberAttribute>
    <groupMemberFormat>\${dn}</groupMemberFormat>
    <groupObjectClass>groupOfNames</groupObjectClass>
    <userIdAttribute>uid</userIdAttribute>
    <userObjectClass>inetOrgPerson</userObjectClass>
    <userBaseDn>ou=people</userBaseDn>
    <userRealNameAttribute>cn</userRealNameAttribute>
  </userAndGroupConfig>
</ldapConfiguration>
_LDAP_XML

# Map LDAP groups to Nexus roles
cat >conf/security.xml <<_SECURITY_XML
<?xml version="1.0" encoding="UTF-8"?>
<security>
  <version>2.0.5</version>
  <users>
    <user>
      <id>anonymous</id>
      <firstName>Nexus</firstName>
      <lastName>Anonymous User</lastName>
      <password>\$shiro1\$SHA-512\$1024\$ez2GLaqC0+ciTR5f24eCWQ==\$l+6dNgNESsonACRb3JvpxBOuhlBxIHB7GJ9gJgAI7uAnFd+dSermmS9p+ZBwJpYC7MhFWMrokxW3x7CUCm6gMw==</password>
      <status>active</status>
    </user>
  </users>
  <roles>
    <role>
      <id>admins</id>
      <name>admins</name>
      <description>External mapping for admins (LDAP)</description>
      <roles>
        <role>nx-admin</role>
      </roles>
    </role>
    <role>
      <id>robots</id>
      <name>robots</name>
      <description>External mapping for users (LDAP)</description>
      <privileges>
        <privilege>65</privilege>
      </privileges>
      <roles>
        <role>nx-deployment</role>
        <role>repository-any-full</role>
      </roles>
    </role>
    <role>
      <id>users</id>
      <name>users</name>
      <description>External mapping for users (LDAP)</description>
      <roles>
        <role>nx-developer</role>
        <role>repository-any-read</role>
      </roles>
    </role>
  </roles>
  <userRoleMappings>
    <userRoleMapping>
      <userId>anonymous</userId>
      <source>default</source>
      <roles>
        <role>anonymous</role>
        <role>repository-any-read</role>
      </roles>
    </userRoleMapping>
  </userRoleMappings>
</security>
_SECURITY_XML

cat >conf/security-configuration.xml <<_SECURITY_CONFIGURATION_XML
<?xml version="1.0"?>
<security-configuration>
  <version>2.0.8</version>
  <anonymousAccessEnabled>true</anonymousAccessEnabled>
  <anonymousUsername>anonymous</anonymousUsername>
  <anonymousPassword>{cnjBG7lrND8H010gnv/UIONZGpSyqT4gatmreNVL+fc=}</anonymousPassword>
  <realms>
    <realm>LdapAuthenticatingRealm</realm>
    <realm>XmlAuthenticatingRealm</realm>
    <realm>XmlAuthorizingRealm</realm>
  </realms>
  <hashIterations>1024</hashIterations>
</security-configuration>
_SECURITY_CONFIGURATION_XML

umask $save_umask
cd "$workdir"


# Proceed with CMD
touch /var/lock/initialized
exec "$@"

