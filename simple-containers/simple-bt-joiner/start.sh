#!/bin/sh

# Manually start dbus
mkdir -p /var/run/dbus
/usr/bin/dbus-daemon --system

# Manually start bluez
/usr/lib/bluetooth/bluetoothd &

mount -t debugfs none /sys/kernel/debug

# Execute all the rest
exec "$@"
