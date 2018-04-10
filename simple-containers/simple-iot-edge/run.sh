#!/bin/bash
set -x

[ `arch` == aarch64 ] && arch="arm"
[ `arch` == armhf ] && arch="arm"
[ `arch` == armv7l ] && arch="arm"

[ `arch` == x86_64 ] && arch="amd64"
[ `arch` == i386 ] && arch="amd64"

[ $arch == "arm" ] && image=' --image microsoft/azureiotedge-agent:1.0.0-preview022-linux-arm32v7 '
[ $arch == "amd64" ] && image=' --image microsoft/azureiotedge-agent:1.0.0-preview022-linux-amd64 '

iotedgectl setup $image --connection-string "$CONNECTIONSTRING" --auto-cert-gen-force-no-passwords
iotedgectl start
