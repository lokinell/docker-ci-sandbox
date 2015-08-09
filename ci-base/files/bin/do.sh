#!/bin/bash
#
# Docker container ENTRYPOINT script.
# It initializes the container and run the CMD process.
#
# It runs as the applcation user set by USER directive in Dockerfile or
# "-u" Docker CLI option. It may or may not be "root".
#

set -e ${DEBUG:+-x}

run_sh() {
    for script in "$@"; do
        [ -f "$script" ] || continue
        $SHELL "$script"
    done
}

on_failure() {
    echo "Initialization failure${script:+: $script exit status $?}" >&2
}
trap on_failure EXIT


# Initialize container filesystem when it is created (on `docker run`).
# It handles service creation or upgrade.
#
# It scans /opt/<package>/ and /opt/<provider>/<package>/ directories, then
# looks to etc/init/container.d/ and run all *.sh scripts there using Bash.
#
# /var/run/ is local to the container, so it is persisted with the container.
#
if [ ! -f /var/run/entrypoint/initialized ]; then

    echo "Container initialization..."
    run_sh /opt/*/etc/init/container.d/*.sh \
            /opt/*/*/etc/init/container.d/*.sh
    echo "Container initialization complete"

    touch /var/run/entrypoint/initialized
fi

# Initialize container data on Docker volumes.
# It handles initial service creation.
#
# It works like container initialization but looks to etc/init/volume.d/.
#
if [ ! -f /var/opt/entrypoint/initialized ]; then

    echo "Volumes initialization..."
    run_sh /opt/*/etc/init/volume.d/*.sh \
            /opt/*/*/etc/init/volume.d/*.sh
    echo "Volumes initialization complete"

    touch /var/opt/entrypoint/initialized
fi


# Run the container process (from CMD or `docker run`).
#
exec "$@"
