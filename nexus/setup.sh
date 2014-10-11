#!/bin/sh -e
#
# Initialize Nexus data
#
# Assume the current directory (set by WORKDIR in Dockerfile)
# is Nexus home directory.
#

# Expected environment variables
echo "Test environment configuration..."
[ -f `basename "$0"` ]
[ "$TMP" ]
[ $(id -u) -eq 0 ]
echo "Succeeded"

user=nexus

cd ../sonatype-work
[ ! -d nexus/conf ] || exit 0


# The following steps are for initial bootstrapping only

mkdir -p nexus/conf
chown -R $user nexus
cd nexus

# LDAP server connection
su $user -c "cat >conf/ldap.xml" <<_LDAP_XML
<?xml version="1.0" encoding="UTF-8"?>
<ldapConfiguration>
  <version>2.8.0</version>
  <connectionInfo>
    <searchBase>dc=asf,dc=griddynamics,dc=com</searchBase>
    <systemUsername>cn=admin,dc=asf,dc=griddynamics,dc=com</systemUsername>
    <!-- FIXME: Hard-coded encrypted password to LDAP server -->
    <systemPassword>CMkW0HMMRFCK9kUsr00=</systemPassword>
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
chmod 640 conf/ldap.xml

# Map LDAP groups to Nexus roles
su $user -c "cat >conf/security.xml" <<_SECURITY_XML
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
chmod 640 conf/security.xml

su $user -c "cat >conf/security-configuration.xml" <<_SECURITY_CONFIGURATION_XML
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
chmod 640 conf/security-configuration.xml

