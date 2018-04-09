#/bin/sh

set -x

docker-compose -H unix:///var/run/docker.sock -f /$TARGET up -d
