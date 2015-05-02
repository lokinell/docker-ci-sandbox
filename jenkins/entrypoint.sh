#!/bin/sh -e
#
# Docker container ENTRYPOINT for jenkins
# Initial Jenkins runtime configuration.
#


# Assume the current directory (set by WORKDIR in Dockerfile)
# is Jenkins installation directory.
# TODO: Set $HOME when Jenkins will be run as "jenkins" user instead of "root".
#
jenkins_home=$(pwd)

# Expected environment variables
# to be passed from Docker command line, Dockerfile or fig.yml:
#
echo "Test environment configuration..."
[ "$ldap_admin_password" ]
echo "Succeeded"

[ ! -f /var/lock/initialized ] || exec "$@"


# The following steps are for initial bootstrapping only

# Set password to bind to LDAP in Jenkins config.
password64=$(echo -n "$ldap_admin_password" | base64)
sed -i "s|<\(managerPassword\)>[^<]*</\1>|<\1>${password64}</\1>|" \
    config.xml


# Proceed with CMD
#
touch /var/lock/initialized
cd "$jenkins_home"
exec "$@"

