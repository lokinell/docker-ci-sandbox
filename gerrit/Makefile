# gerrit
#

.PHONY: all keys clean

all: keys

keys: ssh/jenkins_id_rsa.pub ssh/jenkinsslave_id_rsa.pub

ssh/jenkins_id_rsa.pub: ../jenkins/ssh/id_rsa.pub
	[ -d ssh ] || mkdir ssh
	umask 022 && cat $< >$@

ssh/jenkinsslave_id_rsa.pub: ../jenkins-slave/ssh/id_rsa.pub
	[ -d ssh ] || mkdir ssh
	umask 022 && cat $< >$@

../%:
	$(MAKE) -C $(subst /$*,,$@) $*

clean:
	rm -rf ssh
