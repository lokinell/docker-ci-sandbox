# gerrit
#
# Gerrit code review and Git repositories server
#
# Build:
# sudo docker build -t gerrit:latest .
#
# Run:
# sudo docker run -d -p 127.0.0.1:8083:8080 -p 127.0.0.1:29418:29418 -h gerrit --name gerrit gerrit 
#

FROM ci-base:centos
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

ENV gerrit_version 2.10
ENV TMP /tmp

RUN yum -y install openssh-clients git gitweb

# Gerrit user
RUN useradd -c 'Gerrit code review' -d /var/lib/gerrit -M -N -g nobody -G lock -r -u 201 gerrit
RUN mkdir ~gerrit && chown gerrit ~gerrit

USER gerrit
WORKDIR /var/lib/gerrit

RUN mkdir etc

# Generate SSH keys
RUN ssh-keygen -q -t rsa -P '' -f etc/ssh_host_rsa_key \
    && ssh-keygen -q -t dsa -P '' -f etc/ssh_host_dsa_key

# Configure Gerrit DB and directories
RUN git config -f etc/gerrit.config database.type h2 \
    && git config -f etc/gerrit.config database.database db/ReviewDB \
    && git config -f etc/gerrit.config gerrit.basePath git \
    && git config -f etc/gerrit.config cache.directory cache

# Install Gerrit
RUN wget -q -O /tmp/gerrit.war "http://gerrit-releases.storage.googleapis.com/gerrit-${gerrit_version}.war" \
    && java -jar /tmp/gerrit.war init -d . --batch --no-auto-start \
        --install-plugin download-commands --install-plugin reviewnotes --install-plugin replication \
    && rm /tmp/gerrit.war

# Configure Gerrit:
# setup remote JMX access, LDAP authentication and GitWeb.
RUN git config -f etc/gerrit.config gerrit.canonicalWebUrl 'http://localhost:8083/' \
    && git config -f etc/gerrit.config container.javaOptions '-Dcom.sun.management.jmxremote.port=8099 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false' \
    && git config -f etc/gerrit.config auth.type LDAP \
    && git config -f etc/gerrit.config ldap.server 'ldap://ldap' \
    && git config -f etc/gerrit.config ldap.accountBase 'ou=people,dc=asf,dc=griddynamics,dc=com' \
    && git config -f etc/gerrit.config ldap.accountPattern 'uid=${username}' \
    && git config -f etc/gerrit.config ldap.accountFullName 'displayName' \
    && git config -f etc/gerrit.config ldap.accountEmailAddress 'mail' \
    && git config -f etc/gerrit.config ldap.groupBase 'ou=groups,dc=asf,dc=griddynamics,dc=com' \
    && git config -f etc/gerrit.config ldap.groupMemberPattern '(|(member=${dn})(uniqueMember=${dn}))' \
    && git config -f etc/gerrit.config sendemail.smtpServer localhost \
    && git config -f etc/gerrit.config sshd.listenAddress '*:29418' \
    && git config -f etc/gerrit.config httpd.listenUrl 'http://*:8080/' \
    && git config -f etc/gerrit.config gitweb.cgi '/var/www/git/gitweb.cgi' \
    && git config -f etc/gerrit.config gc.startTime 'Sat 23:30' \
    && git config -f etc/gerrit.config gc.interval '1 week'

USER root

# Link to Jenkins
COPY ssh/jenkins_id_rsa.pub /var/lib/gerrit/etc/
COPY ssh/jenkinsslave_id_rsa.pub /var/lib/gerrit/etc/

# entrypoint script handles initialization
COPY entrypoint.sh /entrypoint
RUN chown gerrit /entrypoint && chmod 700 /entrypoint

USER gerrit

# Application ports
EXPOSE 8080 29418
# JMX RMI port
EXPOSE 8099

ENTRYPOINT ["/entrypoint"]
CMD ["bin/gerrit.sh", "run"]

