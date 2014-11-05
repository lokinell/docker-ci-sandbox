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

# Download and install Nexus
RUN cd /var/lib \
    && wget -q -O /tmp/nexus-bundle.tar.gz http://www.sonatype.org/downloads/nexus-${nexus_version}-bundle.tar.gz \
    && checksum=$(wget -q -O- http://www.sonatype.org/downloads/nexus-${nexus_version}-bundle.tar.gz.sha1) \
    && [ $(sha1sum /tmp/nexus-bundle.tar.gz | cut -f1 -d' ') = $checksum ] \
    && tar -xzf /tmp/nexus-bundle.tar.gz \
    && ln -s nexus-${nexus_version}* nexus \
    && chown -R nexus sonatype-work/nexus \
    && rm /tmp/nexus-bundle.tar.gz

WORKDIR /var/lib/nexus

# Adjust Nexus startup script
RUN sed -e 's:^#*\(RUN_AS_USER\)=.*:\1=nexus:' \
    -e 's:^#*\(PIDDIR\)=.*:\1=/var/run/nexus:' \
    -e 's:\<\(wrapper.daemonize\)=[^ ]\+:\1=FALSE:' \
    -i bin/nexus

# Runtime data dir
RUN mkdir /var/run/nexus && chown nexus:root /var/run/nexus

# Data dirs for JSW
# TODO: Get rid of it
RUN chown nexus logs tmp

# entrypoint script handles initialization
COPY entrypoint.sh /entrypoint
RUN chown nexus /entrypoint && chmod 700 /entrypoint

USER nexus

ENTRYPOINT ["/entrypoint"]
CMD ["bin/nexus", "start"]

