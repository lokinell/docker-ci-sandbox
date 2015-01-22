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

FROM ci-base
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 8080

ENV jenkins_version 1.580.2
ENV TMP /tmp

# Install Jenkins
RUN apt-get -qy install daemon psmisc
RUN wget -q -O /tmp/jenkins.deb "http://pkg.jenkins-ci.org/debian-stable/binary/jenkins_${jenkins_version}_all.deb" \
    && dpkg -i /tmp/jenkins.deb && rm /tmp/jenkins.deb

# Hack to run Jenkins in foreground
RUN echo 'JENKINS_HOME="/var/lib/jenkins -f"' >>/etc/default/jenkins

# Directories for build records and workspaces
RUN mkdir /var/lib/jenkins-builds && chown jenkins /var/lib/jenkins-builds
RUN mkdir /var/lib/jenkins-ws && chown jenkins /var/lib/jenkins-ws

WORKDIR /var/lib/jenkins

USER jenkins

# Pludins
#
# Disable unnecessary plugins
RUN mkdir plugins && cd plugins \
    && touch cvs.jpi.disabled translation.jpi.disabled
#
# Install plugins
#
# 1.580.2 as of 2015-01-12
ENV plugin_site http://updates.jenkins-ci.org/download/plugins
RUN cd plugins && echo \
    ${plugin_site}/mock-security-realm/1.2/mock-security-realm.hpi \
    ${plugin_site}/git-client/1.15.0/git-client.hpi \
    ${plugin_site}/scm-api/0.2/scm-api.hpi \
    ${plugin_site}/git/2.3.4/git.hpi \
    ${plugin_site}/ssh-agent/1.5/ssh-agent.hpi \
    ${plugin_site}/gerrit-trigger/2.11.1/gerrit-trigger.hpi \
    ${plugin_site}/token-macro/1.10/token-macro.hpi \
    ${plugin_site}/groovy/1.24/groovy.hpi \
    ${plugin_site}/script-security/1.12/script-security.hpi \
    ${plugin_site}/email-ext/2.39/email-ext.hpi \
    ${plugin_site}/config-file-provider/2.7.5/config-file-provider.hpi \
    ${plugin_site}/parameterized-trigger/2.25/parameterized-trigger.hpi \
    ${plugin_site}/promoted-builds/2.19/promoted-builds.hpi \
    ${plugin_site}/copyartifact/1.32.1/copyartifact.hpi \
    ${plugin_site}/cloudbees-folder/4.7/cloudbees-folder.hpi \
    ${plugin_site}/envinject/1.90/envinject.hpi \
    | xargs -t -n1 wget -q -N

USER root

# Basic configuration files and SSH keys
ADD fs/var/lib/jenkins /var/lib/jenkins
ADD ssh/ /var/lib/jenkins/.ssh
RUN chown -R jenkins /var/lib/jenkins

# entrypoint script handles initialization
COPY entrypoint.sh /entrypoint
RUN chown jenkins /entrypoint && chmod 700 /entrypoint

ENTRYPOINT ["/entrypoint"]
CMD ["service", "jenkins", "start"]

