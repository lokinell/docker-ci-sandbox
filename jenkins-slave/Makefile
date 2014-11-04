# jenkins-slave
#

.PHONY: all keys clean

all: keys

keys: ssh/authorized_keys ssh/id_rsa ssh/id_rsa.pub ssh/config

ssh/authorized_keys: ../jenkins/ssh/id_rsa.pub
	[ -d ssh ] || mkdir ssh
	cat $< >$@

ssh/id_rsa:
	[ -d ssh ] || mkdir ssh
	ssh-keygen -q -t rsa -P '' -C 'jenkins-slave' -f $@

ssh/id_rsa.pub: ssh/id_rsa

ssh/config:
	echo "Host *" >$@
	echo "StrictHostKeyChecking no" >>$@

../%:
	$(MAKE) -C $(subst /$*,,$@) $*

clean:
	rm -rf ssh
