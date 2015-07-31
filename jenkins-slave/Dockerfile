# jenkins-slave
#
# SSH slave for Jenkins CI server
#
# Build:
# docker build -t jenkins-slave:latest .
#
# Run:
# docker run -d -h jenkins-slave1 --name jenkins-slave1 jenkins-slave
#

FROM ci-base:centos
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 22

RUN yum -y install openssh-server git unzip \
    && yum -y clean all && rm -rf /var/cache/*
RUN mkdir /var/run/sshd
RUN chmod 0755 /var/run/sshd

# Host key
RUN ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''

# Jenkins user
RUN useradd -c 'Jenkins CI slave' -d /var/lib/jenkins-slave -M -N -g nobody -r jenkins
RUN mkdir ~jenkins
RUN chmod 755 ~jenkins

# Jenkins master key to connect the slave
ADD ssh /var/lib/jenkins-slave/.ssh
RUN chmod -R g-w,o-w /var/lib/jenkins-slave/.ssh

RUN chown -R jenkins /var/lib/jenkins-slave

CMD ["/usr/sbin/sshd", "-D"]

