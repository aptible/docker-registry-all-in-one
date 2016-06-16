#!/bin/bash
set -o errexit
set -o nounset

apt-get update
apt-get install -y swig python-dev python-mysqldb python-rsa libssl-dev liblzma-dev libevent1-dev
rm -rf /var/lib/apt/lists/*

pip install --upgrade pip
pip install docker-registry

# The dependencies packaged by docker-registry are a little broken. So, we need
# to update them.
pip install --upgrade gevent m2crypto

# Put config files in place...
cp /usr/local/lib/python2.7/dist-packages/config/{config_sample.yml,config.yml}
cp /usr/local/lib/python2.7/dist-packages/config/boto.cfg /etc/boto.cfg

# Finally, registry includes a patch for ... boto. The prupose is unclear, but
# we probably need to keep it.
patch "$(python -c 'import boto; import os; print os.path.dirname(boto.__file__)')/connection.py" < /patches/boto_header_patch.diff
