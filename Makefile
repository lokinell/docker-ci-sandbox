#
# Makefile
#  - to prepare the workspace for using Docker containers with Fig;
#  - to upload build tools packages to Nexus.
#

#
# Prepare the workspace for using Docker containers with Fig
#

prepare: images keys

keys: jenkins/keys jenkins-slave/keys gerrit/keys

images:
	cd ci-base && docker build -t ci-base:centos .

clean: jenkins/clean jenkins-slave/clean gerrit/clean

.PHONY: prepare images keys clean

#
# Upload build tools packages to Nexus
#

upload-tools: nexus/upload-tools

.PHONY: upload-tools

#
# Utilities
#

jenkins/%:
	$(MAKE) -C $(subst /$*,,$@) $*

jenkins-slave/%:
	$(MAKE) -C $(subst /$*,,$@) $*

gerrit/%:
	$(MAKE) -C $(subst /$*,,$@) $*

nexus/%:
	$(MAKE) -C $(subst /$*,,$@) $*

