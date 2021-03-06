#!/usr/bin/env bash
set -x

arch="bogus"
[ `arch` == i386 ] && arch="-amd64"
[ `arch` == aarch64 ] && arch="-arm64"
[ `arch` == armhf ] && arch="-arm"
[ `arch` == armv7l ] && arch="-arm"
[ `arch` == x86_64 ] && arch="-amd64"

# create_and_push_manifest
# this function attempts to brute-force push the manifest
function create_and_push_manifest {
    ACCOUNT=$1
    D=$2
    # create a manifest for atleast 1 image
    docker manifest create --amend \
        ${ACCOUNT:-foundriesio}/$D:latest \
            ${ACCOUNT:-foundriesio}/$D:latest$arch

    # create a manifest for atlearst 2 images
    docker manifest create --amend \
        ${ACCOUNT:-foundriesio}/$D:latest \
            ${ACCOUNT:-foundriesio}/$D:latest-arm64 \
            ${ACCOUNT:-foundriesio}/$D:latest-amd64
    docker manifest create --amend \
        ${ACCOUNT:-foundriesio}/$D:latest \
            ${ACCOUNT:-foundriesio}/$D:latest-arm64 \
            ${ACCOUNT:-foundriesio}/$D:latest-arm
    docker manifest create --amend \
        ${ACCOUNT:-foundriesio}/$D:latest \
            ${ACCOUNT:-foundriesio}/$D:latest-arm \
            ${ACCOUNT:-foundriesio}/$D:latest-amd64

    # create a manifest for atleast 2 images
    docker manifest create --amend \
        ${ACCOUNT:-foundriesio}/$D:latest \
            ${ACCOUNT:-foundriesio}/$D:latest-arm64 \
            ${ACCOUNT:-foundriesio}/$D:latest-amd64 \
            ${ACCOUNT:-foundriesio}/$D:latest-arm

    # push the manifest that won the battle
    docker manifest push --purge ${ACCOUNT:-foundriesio}/$D:latest

}

# build docker compose with the local yml files
docker build -f compose-launcher/Dockerfile -t ${ACCOUNT:-foundriesio}/compose-launcher:latest$arch .
docker push ${ACCOUNT:-foundriesio}/compose-launcher:latest$arch
create_and_push_manifest ${ACCOUNT:-foundriesio} "compose-launcher"
