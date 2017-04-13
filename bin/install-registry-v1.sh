#!/bin/bash
set -o errexit
set -o nounset

apt-get update
apt-get install -y swig python-dev python-mysqldb python-rsa libssl-dev liblzma-dev libevent1-dev
rm -rf /var/lib/apt/lists/*

pip install --upgrade pip
pip install "docker-registry==0.9.1" "docker-registry-core==2.0.3"

# The dependencies packaged by docker-registry are a little broken. So, we need
# to update them.
pip install --upgrade "gevent==1.1.2" "m2crypto==0.25.1" "boto==2.46.1"

# Put config files in place...
cp /usr/local/lib/python2.7/dist-packages/config/{config_sample.yml,config.yml}
cp /usr/local/lib/python2.7/dist-packages/config/boto.cfg /etc/boto.cfg
