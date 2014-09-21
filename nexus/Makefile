#
# nexus
#
# Utility Makefile:
# - Uploads distribution packages for build tools.
#

JDK7_VERSION=7u60
JDK7_FILE=jdk-$(JDK7_VERSION)-linux-x64.tar.gz

MAVEN_VERSION=3.2.3
MAVEN_DOWNLOAD_SITE=http://apache-mirror.rbc.ru/pub/apache
MAVEN_FILE=apache-maven-$(MAVEN_VERSION)-bin.zip
MAVEN_FILEPATH=maven/maven-3/$(MAVEN_VERSION)/binaries/$(MAVEN_FILE)

GROOVY_VERSION=2.3.6
GROOVY_FILE=groovy-binary-$(GROOVY_VERSION).zip

# Maven CLI to upload to Nexus
MVN=mvn -B

# Nexus as it visible from host system
NEXUS_URL=http://localhost:8082/nexus
NEXUS_REPOSITORY=thirdparty
NEXUS_USER=deployment
NEXUS_PASSWORD=deployment123


#
# Upload files to Nexus
#

upload-tools: upload-jdk upload-maven upload-groovy

upload-jdk: upload-jdk7
upload-jdk7: upload/$(JDK7_FILE) upload/settings.xml
	curl -sf "$(NEXUS_URL)/service/local/artifact/maven/resolve?r=thirdparty&g=com.oracle.java&a=jdk&v=$(JDK7_VERSION)&c=linux-x64&e=tar.gz" >/dev/null \
	|| $(MVN) -s upload/settings.xml deploy:deploy-file -Dfile=$< \
	-Durl=$(NEXUS_URL)/content/repositories/$(NEXUS_REPOSITORY) \
	-DrepositoryId=$(NEXUS_REPOSITORY) \
	-DgroupId=com.oracle.java \
	-DartifactId=jdk \
	-Dversion=$(JDK7_VERSION) \
	-Dclassifier=linux-x64 \
	-Dpackaging=tar.gz

upload-maven: upload/$(MAVEN_FILE) upload/settings.xml
	curl -sf "$(NEXUS_URL)/service/local/artifact/maven/resolve?r=thirdparty&g=org.apache.maven&a=apache-maven&v=$(MAVEN_VERSION)&c=bin&e=zip" >/dev/null \
	|| $(MVN) -s upload/settings.xml deploy:deploy-file -Dfile=$< \
	-Durl=$(NEXUS_URL)/content/repositories/$(NEXUS_REPOSITORY) \
	-DrepositoryId=$(NEXUS_REPOSITORY) \
	-DgroupId=org.apache.maven \
	-DartifactId=apache-maven \
	-Dversion=$(MAVEN_VERSION) \
	-Dclassifier=bin \
	-Dpackaging=zip

upload-groovy: upload/$(GROOVY_FILE) upload/settings.xml
	curl -sf "$(NEXUS_URL)/service/local/artifact/maven/resolve?r=thirdparty&g=org.codehaus.groovy&a=groovy-binary&v=$(GROOVY_VERSION)&e=zip" >/dev/null \
	|| $(MVN) -s upload/settings.xml deploy:deploy-file -Dfile=$< \
	-Durl=$(NEXUS_URL)/content/repositories/$(NEXUS_REPOSITORY) \
	-DrepositoryId=$(NEXUS_REPOSITORY) \
	-DgroupId=org.codehaus.groovy \
	-DartifactId=groovy-binary \
	-Dversion=$(GROOVY_VERSION) \
	-Dpackaging=zip

upload/settings.xml: settings.xml.in
	touch $@
	chmod 600 $@
	sed "s/%repositoryId%/$(NEXUS_REPOSITORY)/;s/%username%/$(NEXUS_USER)/;s/%password%/$(NEXUS_PASSWORD)/" <$< >$@

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
	cd upload && wget -q -N $(MAVEN_DOWNLOAD_SITE)/$(MAVEN_FILEPATH)
	checksum=$$(wget -q -O- http://www.apache.org/dist/$(MAVEN_FILEPATH).md5) \
	&& [ $$(md5sum $@ | cut -f1 -d' ') = $$checksum ]

upload/$(GROOVY_FILE):
	[ -d upload ] || mkdir upload
	cd upload && wget -q -N http://dl.bintray.com/groovy/maven/$(GROOVY_FILE)

#
# Clean-up
#

clean:
	rm -f upload/$(MAVEN_FILE)
	rm -f upload/$(GROOVY_FILE)
	rm -f upload/settings.xml

