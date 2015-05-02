# jenkins
#
# Jenkins CI server
#
# docker build -t jenkins:latest .
#
# Run:
# docker run -d -p 127.0.0.1:8081:8080 -h dev-jenkins --name dev-jenkins \
#   --link dev-nexus:nexus --link dev-gerrit:gerrit jenkins
#

FROM ci-base:centos
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

ENV jenkins_rpm_version 1.596.2-1.1
ENV TMP /tmp

# Install Jenkins
RUN wget -q -O /tmp/jenkins.rpm "http://pkg.jenkins-ci.org/redhat-stable/jenkins-${jenkins_rpm_version}.noarch.rpm" \
    && rpm -i --excludedocs /tmp/jenkins.rpm \
    && rm /tmp/jenkins.rpm

# Enable remote JMX.
# Enable Extended read permission.
RUN echo 'JENKINS_JAVA_OPTIONS="$JENKINS_JAVA_OPTIONS -Dcom.sun.management.jmxremote.port=8099 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"' >>/etc/sysconfig/jenkins \
    && echo 'JENKINS_JAVA_OPTIONS="$JENKINS_JAVA_OPTIONS -Dhudson.security.ExtendedReadPermission=true"' >>/etc/sysconfig/jenkins

# Hack to run Jenkins in foreground.
RUN sed -i 's/^\(PARAMS=.*\) --daemon/\1/' /etc/init.d/jenkins

# Directories for build records and workspaces
RUN mkdir /var/lib/jenkins-builds && chown jenkins /var/lib/jenkins-builds
RUN mkdir /var/lib/jenkins-ws && chown jenkins /var/lib/jenkins-ws

WORKDIR /var/lib/jenkins

USER jenkins

# Plugins
#
# Disable unnecessary plugins
RUN mkdir plugins && cd plugins \
    && touch cvs.jpi.disabled translation.jpi.disabled
#
# Install plugins
#
# 1.596.2 as of 2015-04-03
ENV plugin_site http://updates.jenkins-ci.org/download/plugins
RUN cd plugins && echo \
    ${plugin_site}/mock-security-realm/1.2/mock-security-realm.hpi \
    ${plugin_site}/git-client/1.16.1/git-client.hpi \
    ${plugin_site}/scm-api/0.2/scm-api.hpi \
    ${plugin_site}/git/2.3.5/git.hpi \
    ${plugin_site}/ssh-agent/1.5/ssh-agent.hpi \
    ${plugin_site}/gerrit-trigger/2.12.0/gerrit-trigger.hpi \
    ${plugin_site}/token-macro/1.10/token-macro.hpi \
    ${plugin_site}/groovy/1.24/groovy.hpi \
    ${plugin_site}/script-security/1.12/script-security.hpi \
    ${plugin_site}/email-ext/2.39.3/email-ext.hpi \
    ${plugin_site}/config-file-provider/2.7.5/config-file-provider.hpi \
    ${plugin_site}/parameterized-trigger/2.26/parameterized-trigger.hpi \
    ${plugin_site}/promoted-builds/2.20/promoted-builds.hpi \
    ${plugin_site}/copyartifact/1.35/copyartifact.hpi \
    ${plugin_site}/cloudbees-folder/4.7/cloudbees-folder.hpi \
    ${plugin_site}/envinject/1.91.1/envinject.hpi \
    | xargs -t -n1 wget -q -N

USER root

# Basic configuration files and SSH keys
ADD fs/ /
ADD ssh/ /var/lib/jenkins/.ssh
RUN chown -R jenkins /var/lib/jenkins \
    && chmod 700 /usr/local/bin/*

# entrypoint script handles initialization
COPY entrypoint.sh /entrypoint
RUN chown jenkins /entrypoint && chmod 700 /entrypoint

# Application ports
EXPOSE 8080
# JMX RMI port
EXPOSE 8099

ENTRYPOINT ["/entrypoint"]
CMD ["jenkins"]

