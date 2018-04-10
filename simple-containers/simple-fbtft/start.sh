#!/bin/sh
set -x

/lib/systemd/systemd-udevd --daemon &> /dev/null
udevadm trigger &> /dev/null

# Execute all the rest
exec "$@"
