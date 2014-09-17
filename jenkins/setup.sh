#!/bin/sh -e
#
# Initialize Jenkins data
#
# Assume the current directory (set by WORKDIR in Dockerfile)
# is Jenkins home directory.
#

# Expected environment variables
echo "Test environment configuration..."
[ "$TMP" ]
[ "$jenkins_save_dir" ]
[ $(id -u) -eq 0 ]
echo "Succeeded"

user=jenkins
jenkins_home=$(pwd)

[ ! -d plugins ] || exit 0


# The following steps are for initial bootstrapping only

# Restore archived Jenkins data.
#
chown $user .
chown $user /var/lib/jenkins-builds /var/lib/jenkins-ws
su $user -c "sh -sex" <<_RESTORE
cd "$jenkins_save_dir"
cp -pr . "$jenkins_home"
_RESTORE
rm -rf "$jenkins_save_dir"

