#!/bin/bash
set -o errexit
set -o nounset

export GOPATH=/go

apt-get update
apt-get -y install golang librados2
rm -rf /var/lib/apt/lists/*

GOPKG="github.com/docker/distribution"

go get "$GOPKG"
cd "/go/src/${GOPKG}"
make clean binaries

mkdir -p /etc/docker/registry

mv "/go/src/${GOPKG}/bin/"* /usr/local/bin
cp "/go/src/${GOPKG}/cmd/registry/config-example.yml" /etc/docker/registry/config.yml
