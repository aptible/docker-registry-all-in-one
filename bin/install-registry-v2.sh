#!/bin/bash
set -o errexit
set -o nounset

export GOPATH=/go

apt-get update
apt-get -y install librados2
rm -rf /var/lib/apt/lists/*

# Install Go (Xenial only provides Go 1.6.2, and the latest Distribution
# requires Context, available only in Go 1.8+, so we install from Google)
GO_VERSION=1.8.3
GO_SHA256SUM=1862f4c3d3907e59b04a757cfda0ea7aa9ef39274af99a784f5be843c80c6772
GO_FILENAME="go${GO_VERSION}.linux-amd64.tar.gz"

cd /tmp
curl -O "https://storage.googleapis.com/golang/${GO_FILENAME}"
echo "${GO_SHA256SUM} ${GO_FILENAME}" | sha256sum -c
tar xzf "$GO_FILENAME"
mv go /usr/local/
rm "$GO_FILENAME"

GOPKG="github.com/docker/distribution"
GIT_REF="5db89f0ca68677abc5eefce8f2a0a772c98ba52d"

go get "$GOPKG"

cd "/go/src/${GOPKG}"
git checkout "$GIT_REF"
make clean binaries

mkdir -p /etc/docker/registry

mv "/go/src/${GOPKG}/bin/"* /usr/local/bin/
