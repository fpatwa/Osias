#!/bin/bash

set -euxo pipefail

MONITOR_IP=$1

# Fetch most recent version of cephadm
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm

# Add ceph GPG Key
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -

chmod +x cephadm
sudo ./cephadm add-repo --release octopus
sudo ./cephadm install ceph-common
sudo ./cephadm install

sudo mkdir -p /etc/ceph
sudo ./cephadm bootstrap --mon-ip "$MONITOR_IP"

sudo ceph -v
sudo ceph status
