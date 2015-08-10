Entrypoint
----------

The image contains a generic initialialization script (`/opt/bin/do`) that is
installed as `ENTRYPOINT` in inheriting containers. The script expects that
`/var/opt` is on a Docker volume.

The script serves packages installed in `/opt/<package>` and
`/opt/<provider>/<package>`. In the package directories it looks to `etc/init`
subdirectories (see below) for shell scripts and executes them.

### Initialization cases

#### Service bootstrapping

`etc/init/volume.d/*.sh` (`/opt/<package>/etc/init/volume.d/*.sh`,
`/opt/<provider>/<package>/etc/init/volume.d/*.sh`).

Runs once when service data on Docker volumes is initialized.

#### Container upgrade

`etc/init/container.d/*.sh` (`/opt/<package>/etc/init/container.d/*.sh`,
`/opt/<provider>/<package>/etc/init/container.d/*.sh`)

Runs when a new container is started. It happends when the service (container
and its data0 is crested for 1st time and when the container is re-created on
top ot existing data in volumes.
