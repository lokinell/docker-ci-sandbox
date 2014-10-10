KEYS = id_rsa id_rsa.pub

.PHONY: all keys clean

all: keys

keys: $(addprefix ssh/,$(KEYS))

ssh/id_rsa:
	[ -d ssh ] || mkdir ssh
	ssh-keygen -q -t rsa -P '' -C 'jenkins-bot' -f $@

ssh/id_rsa.pub: ssh/id_rsa

../%:
	$(MAKE) -C $(subst /$*,,$@) $*

clean:
	rm -rf ssh

