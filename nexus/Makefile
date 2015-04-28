#
# nexus
#
# Utility Makefile:
# - Uploads distribution packages for build tools.
#

JDK7_VERSION=7u67
JDK7_FILE=jdk-$(JDK7_VERSION)-linux-x64.tar.gz

MAVEN_VERSION=3.2.3
MAVEN_FILE=apache-maven-$(MAVEN_VERSION)-bin.zip
MAVEN_DOWNLOAD_URL=http://search.maven.org/remotecontent?filepath=org/apache/maven/apache-maven/$(MAVEN_VERSION)/$(MAVEN_FILE)

GROOVY_VERSION=2.3.6
GROOVY_FILE=groovy-binary-$(GROOVY_VERSION).zip
GROOVY_DOWNLOAD_URL=http://dl.bintray.com/groovy/maven/$(GROOVY_FILE)

# Nexus as it visible from host system
NEXUS_URL=http://localhost:8082/nexus
NEXUS_REPOSITORY=thirdparty
NEXUS_USER=jenkins-bot
NEXUS_PASSWORD=jenkins


#
# Upload files to Nexus
#

upload-tools: upload-jdk upload-maven upload-groovy

upload-jdk: upload-jdk7
upload-jdk7: upload/$(JDK7_FILE)
	curl -sf "$(NEXUS_URL)/service/local/artifact/maven/resolve?r=$(NEXUS_REPOSITORY)&g=com.oracle.java&a=jdk&v=$(JDK7_VERSION)&c=linux-x64&e=tar.gz" >/dev/null \
	|| curl -sSf -u "$(NEXUS_USER):$(NEXUS_PASSWORD)" \
	-F hasPom=false \
	-F r=$(NEXUS_REPOSITORY) \
	-F g=com.oracle.java \
	-F a=jdk \
	-F v=$(JDK7_VERSION) \
	-F c=linux-x64 \
	-F e=tar.gz \
	-F p=pom \
	-F file=@$< \
	$(NEXUS_URL)/service/local/artifact/maven/content >/dev/null

upload-maven: upload/$(MAVEN_FILE)
	curl -sf "$(NEXUS_URL)/service/local/artifact/maven/resolve?r=$(NEXUS_REPOSITORY)&g=org.apache.maven&a=apache-maven&v=$(MAVEN_VERSION)&c=bin&e=zip" >/dev/null \
	|| curl -sSf -u "$(NEXUS_USER):$(NEXUS_PASSWORD)" \
	-F hasPom=false \
	-F r=$(NEXUS_REPOSITORY) \
	-F g=org.apache.maven \
	-F a=apache-maven \
	-F v=$(MAVEN_VERSION) \
	-F c=bin \
	-F e=zip \
	-F p=pom \
	-F file=@$< \
	$(NEXUS_URL)/service/local/artifact/maven/content >/dev/null

upload-groovy: upload/$(GROOVY_FILE)
	curl -sf "$(NEXUS_URL)/service/local/artifact/maven/resolve?r=$(NEXUS_REPOSITORY)&g=org.codehaus.groovy&a=groovy-binary&v=$(GROOVY_VERSION)&e=zip" >/dev/null \
	|| curl -sSf -u "$(NEXUS_USER):$(NEXUS_PASSWORD)" \
	-F hasPom=false \
	-F r=$(NEXUS_REPOSITORY) \
	-F g=org.codehaus.groovy \
	-F a=groovy-binary \
	-F v=$(GROOVY_VERSION) \
	-F e=zip \
	-F p=pom \
	-F file=@$< \
	$(NEXUS_URL)/service/local/artifact/maven/content >/dev/null

#
# Get files to upload
#

upload/$(JDK7_FILE):
	[ -d upload ] || mkdir upload
	@echo "missing $@: JDK 7 file must be downloaded manually from"
	@echo "http://www.oracle.com/technetwork/java/javase/downloads/index.html"
	@false

upload/$(MAVEN_FILE):
	[ -d upload ] || mkdir upload
	cd upload && wget -q --trust-server-names -N "$(MAVEN_DOWNLOAD_URL)"
	checksum=$$(wget -q -O- "$(MAVEN_DOWNLOAD_URL).sha1") \
	&& [ $$(sha1sum $@ | cut -f1 -d' ') = $$checksum ]

upload/$(GROOVY_FILE):
	[ -d upload ] || mkdir upload
	cd upload && wget -q -N "$(GROOVY_DOWNLOAD_URL)"
	checksum=$$(wget -q -O- "$(GROOVY_DOWNLOAD_URL).sha1") \
	&& [ $$(sha1sum $@ | cut -f1 -d' ') = $$checksum ]

#
# Clean-up
#

clean:
	rm -f upload/$(MAVEN_FILE)
	rm -f upload/$(GROOVY_FILE)

