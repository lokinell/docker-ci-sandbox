#!/bin/sh -e
#
# Initialize Nexus data
#
# Assume the current directory (set by WORKDIR in Dockerfile)
# is Nexus home directory.
#

# Expected environment variables
echo "Test environment configuration..."
[ "$TMP" ]
[ $(id -u) -eq 0 ]
echo "Succeeded"

cd ../sonatype-work

[ -d nexus ] || mkdir nexus
chown nexus nexus

