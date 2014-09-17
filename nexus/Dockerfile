# nexus
#
# Nexus binary repository server
#
# Build:
# docker build -t nexus:latest .
#
# Run:
# docker run -d -p 127.0.0.1:8082:8081 -h nexus --name nexus nexus
#

FROM ci-base
MAINTAINER Kirill Evstigneev <kevstigneev@griddynamics.com>

EXPOSE 8081

ENV nexus_version 2.9.1
ENV TMP /tmp

# Nexus user
RUN useradd -c 'Nexus repository server' -d /var/lib/nexus -M -N -g nogroup -r nexus

# Runtime data dir
RUN mkdir /var/run/nexus && chown nexus:root /var/run/nexus

# Make /var/lib world-writable to allow installation by Nexus user
RUN chmod o+w /var/lib

USER nexus
WORKDIR /var/lib

# Download and install Nexus
RUN wget -q -O /tmp/nexus-bundle.tar.gz http://www.sonatype.org/downloads/nexus-${nexus_version}-bundle.tar.gz \
    && checksum=$(wget -q -O- http://www.sonatype.org/downloads/nexus-${nexus_version}-bundle.tar.gz.sha1) \
    && [ $(sha1sum /tmp/nexus-bundle.tar.gz | cut -f1 -d' ') = $checksum ] \
    && nexus_name=$(tar -tzf /tmp/nexus-bundle.tar.gz | grep "^nexus-${nexus_version}-" | cut -f1 -d/ | sort -u) \
    && tar -xzf /tmp/nexus-bundle.tar.gz \
    && ln -s $nexus_name nexus \
    && rm /tmp/nexus-bundle.tar.gz

WORKDIR /var/lib/nexus

# Adjust Nexus startup script
RUN sed -e 's:^#*\(RUN_AS_USER\)=.*:\1=nexus:' \
    -e 's:^#*\(PIDDIR\)=.*:\1=/var/run/nexus:' \
    -e 's:\<\(wrapper.daemonize\)=[^ ]\+:\1=FALSE:' \
    -i bin/nexus

# 'setup' bootstraping script
COPY setup.sh /var/lib/nexus/

USER root
RUN chmod o-w /var/lib

USER nexus
CMD ["bin/nexus", "start"]

