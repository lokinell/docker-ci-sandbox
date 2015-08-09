#!/bin/bash
#
# Docker container ENTRYPOINT script.
# It initializes the container and run the CMD process.
#
# It runs as the applcation user set by USER directive in Dockerfile or
# "-u" Docker CLI option. It may or may not be "root".
#

set -e

on_failure() {
    echo "Initialization failure${script:+: $script exit status $?}" >&2
}
trap on_failure EXIT


# Run it when the container is created (on `docker run`).
# It handles service creation or upgrade.
#
# It scans all /opt/<provider>/<package>/ directories, then looks to
# etc/init/container.d/ and run all *.sh scripts there using Bash.
#
# /var/run/ is local to the container, so it is persisted with the container.
#
if [ ! -f /var/run/entrypoint/initialized ]; then

    echo "Container initialization..."
    for script in /opt/*/etc/init/container.d/*.sh \
                  /opt/*/*/etc/init/container.d/*.sh; do
        [ -f "$script" ] || continue
        $SHELL "$script"
    done
    echo "Container initialization complete"

    touch /var/run/entrypoint/initialized
fi


# Run the container process (from CMD or `docker run`).
#
exec "$@"
