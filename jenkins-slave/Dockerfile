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

FROM ci-base:ubuntu
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 22

RUN apt-get -qy install openssh-server git unzip
RUN mkdir /var/run/sshd
RUN chmod 0755 /var/run/sshd

# Jenkins user
RUN useradd -c 'Jenkins CI slave' -d /var/lib/jenkins-slave -M -N -g nogroup -r jenkins
RUN mkdir ~jenkins
RUN chmod 755 ~jenkins

# Jenkins master key to connect the slave
ADD ssh /var/lib/jenkins-slave/.ssh
RUN chmod -R g-w,o-w /var/lib/jenkins-slave/.ssh

RUN chown -R jenkins /var/lib/jenkins-slave

CMD ["/usr/sbin/sshd", "-D"]

