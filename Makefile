#
# Makefile to prepare the workspace for using Docker containers with Fig.
#

.PHONY: all images keys clean

all: images keys

keys: jenkins/keys jenkins-slave/keys gerrit/keys

images:
	docker build -t ci-base:latest ci-base
	docker build -t volume:latest volume

clean: jenkins/clean jenkins-slave/clean gerrit/clean

jenkins/%:
	$(MAKE) -C $(subst /$*,,$@) $*

jenkins-slave/%:
	$(MAKE) -C $(subst /$*,,$@) $*

gerrit/%:
	$(MAKE) -C $(subst /$*,,$@) $*

