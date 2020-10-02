#!/bin/bash

set -euxo pipefail

MONITOR_IP=$1

sudo apt update
# Fetch most recent version of cephadm
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm

chmod +x cephadm
sudo ./cephadm add-repo --release octopus

# Fix ceph.release.gpg unsupported filetype issue.
sudo -s curl https://download.ceph.com/keys/release.asc | gpg --no-default-keyring --keyring /tmp/fix.gpg --import - && gpg --no-default-keyring --keyring /tmp/fix.gpg --export > /tmp/ceph.release.gpg && rm /tmp/fix.gpg
sudo mv /tmp/ceph.release.gpg /etc/apt/trusted.gpg.d/ceph.release.gpg

# Cephadm will not install unless repo is updated after octopus is added in.
sudo apt update
sudo ./cephadm install ceph-common
sudo ./cephadm install

sudo mkdir -p /etc/ceph
sudo ./cephadm bootstrap --mon-ip "$MONITOR_IP"

sudo ceph -v
sudo ceph status
