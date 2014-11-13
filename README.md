Continuous Delivery automation sandbox
======================================

Set of Docker containers to run CD automation services

 - Gerrit Code Review,
 - Jenkins CI,
 - Sonatype Nexus.

The services are configured to work together.
Containers run on a single machine and orchestrated by Fig.
Services listen on localhost (127.0.0.1) address and not visible from outside.

It works on recent Linux distributions supported by Docker, e.g.
Ubuntu - 12.04 and up.
MacOS requires some tweaks with network configuration.

The whole setup is kept as simple as possible with minimum tools involved
and minimum changes made to stock configurations.


Install prerequisites
----------------------

Installation steps for Ubuntu/Debian.

### Docker

[Docker](https://docker.com/) 1.0.0+ is required.
See [installation manual](https://docs.docker.com/installation/).

Configure Docker access without `sudo`:

    sudo groupad docker
    sudo gpasswd -a `id -un` docker
    sudo restart docker

Relogin to get 'docker' group membership.

### Fig

[Fig](http://www.fig.sh/) - Make for Docker.
See [installation manual](http://www.fig.sh/install.html).

### GNU make

    sudo apt-get install make


Build base images
-----------------

    make images


Generate SSH keys
-----------------

    make keys


Create service containers
-------------------------

Service | Username    | Password    | URL
--------|-------------|-------------|-----------------------------------
ldap    | admin(\*)   | admin       | http://localhost:8084/phpldapadmin (\*\*\*)
gerrit  | admin(\*\*) | admin(\*\*) | http://localhost:8083
nexus   | admin(\*\*) | admin(\*\*) | http://localhost:8082/nexus
jenkins | admin(\*\*) | admin(\*\*) | http://localhost:8081

(\*) LDAP administrator DN: cn=admin,dc=asf,dc=griddynamics,dc=com  
(\*\*) Authentication is controlled by LDAP database.  
(\*\*\*) LDAP UI is provided by ldapAdmin stateless service.

### Container dependencies

                           +-- nexus <--+--------------+
                          /              \              \
    ldapadmin --> ldap <-+----------- jenkins --> jenkinsslave
                          \              /              /
                           +-- gerrit <-+--------------+

It means `fig up jenkins` also brings up 4 service containers Jenkins depends
on.

### Start / Stop / Upgrade service containers

Service (`{service}` below) - gerrit, jenkins, nexus, ldap.
Services data is persisted in
[Docker volumes](https://docs.docker.com/userguide/dockervolumes/) attached to
the service containers.

Create and start a service container:

    fig up -d {service}

Stop a service:

    fig stop {service}

start it again:

    fig start {service}

Upgrade to the current code rebuild the images, stop the service:

    fig build {service}

and then proceed with steps to start the service (see above).


Upload bundles for Jenkins build tools
--------------------------------------

Oracle JDK download cannot be automated. Get `jdk-7u67-linux-x64.tar.gz` from
[OTN download page](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
and save to `nexus/upload` directory. The exact version of JDK is important -
it is hard-coded in Nexus' [`Makefile`](nexus/Makefile) and Jenkins' 
[`config.xml`](jenkins/fs/var/lib/jenkins/config.xml).

Then upload installation bundles for build tools (JDK, Maven, Groovy) to Nexus:

    make upload-tools


Authentication
--------------

Services use LDAP provided by ldap service for authentication.

Users in LDAP must be entities of `inetOrgPerson` class in `ou=people` subtree
with `uid` attribute as RDN. The required attribures are:

Attribute     | Content
--------------|--------------------------------------
**cn**        | User ID (must be unique)
**sn**        | "Lastname"
displayName   | "Firstname Lastname"
Email         | email address
givenName     | "Firstname"
**Password**  | password
**User Name** | Same as **cn**

User groups in LDAP must be of `groupOfNames` class in `ou=groups` subtree
with `cn` as RDN.


Miscellaneous
-------------

### HTTP proxy

(requires a local HTTP proxy listening on TCP port 3128).

For Docker itself - uncomment in `/etc/default/docker`:

    export http_proxy="http://172.17.42.1:3128/"

For scripts inside Dockerfile and containers - `fig.yml` takes advantage
of `http_proxy` environment variable. Run Fig as follows:

    export http_proxy=http://172.17.42.1:3128/ fig ...

