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

ENV nexus_version 2.11.2-06
ENV nexus_sha1 6f89cdef30029aae02c9c64397a6e0b92d6c34c1
ENV TMP /tmp

# Nexus user
RUN useradd -c 'Nexus repository server' -d /var/lib/nexus -M -N -g nogroup -r nexus

# Download and install Nexus
RUN cd /var/lib \
    && wget -q -O /tmp/nexus-bundle.tar.gz http://www.sonatype.org/downloads/nexus-${nexus_version}-bundle.tar.gz \
    && [ $(sha1sum /tmp/nexus-bundle.tar.gz | cut -f1 -d' ') = $nexus_sha1 ] \
    && tar -xzf /tmp/nexus-bundle.tar.gz \
    && ln -s nexus-${nexus_version}* nexus \
    && chown -R nexus sonatype-work/nexus \
    && rm /tmp/nexus-bundle.tar.gz

WORKDIR /var/lib/nexus

# Adjust Nexus startup script
RUN sed -e 's:^#*\(RUN_AS_USER\)=.*:\1=nexus:' \
        -e 's:^#*\(PIDDIR\)=.*:\1=/var/run/nexus:' \
        -e 's:\<\(wrapper.daemonize\)=[^ ]\+:\1=FALSE:' \
        -i bin/nexus \
    && sed -e '$a wrapper.java.additional.4=-Dcom.sun.management.jmxremote.port=8099' \
        -e '$a wrapper.java.additional.5=-Dcom.sun.management.jmxremote.authenticate=false' \
        -e '$a wrapper.java.additional.6=-Dcom.sun.management.jmxremote.ssl=false' \
        -i bin/jsw/conf/wrapper.conf
     

# Runtime data dir
RUN mkdir /var/run/nexus && chown nexus:root /var/run/nexus

# Data dirs for JSW
# TODO: Get rid of it
RUN chown nexus logs tmp

# entrypoint script handles initialization
COPY entrypoint.sh /entrypoint
RUN chown nexus /entrypoint && chmod 700 /entrypoint

USER nexus

# Application ports
EXPOSE 8081
# JMX RMI port
EXPOSE 8099

ENTRYPOINT ["/entrypoint"]
CMD ["bin/nexus", "start"]

