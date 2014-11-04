# gerrit
#

.PHONY: all keys clean

all: keys

keys: ssh/jenkins_id_rsa.pub ssh/jenkinsslave_id_rsa.pub

ssh/jenkins_id_rsa.pub: ../jenkins/ssh/id_rsa.pub
	[ -d ssh ] || mkdir ssh
	cat $< >$@

ssh/jenkinsslave_id_rsa.pub: ../jenkins-slave/ssh/id_rsa.pub
	[ -d ssh ] || mkdir ssh
	cat $< >$@

../%:
	$(MAKE) -C $(subst /$*,,$@) $*

clean:
	rm -rf ssh
