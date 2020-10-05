#!/bin/bash

set -euxo pipefail

MONITOR_IP=$1
CEPH_RELEASE="octopus"

# Update to fetch the latest package index
sudo apt update

# Fetch most recent version of cephadm
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/$CEPH_RELEASE/src/cephadm/cephadm
chmod +x cephadm

# Add ceph package repository
# This will also download the GPG keys which currently is broken
# and the /etc/apt/trusted.gpg.d/ceph.release.gpg file written
# by the cephadm script does not have the correct format
# This key file will be overwritten by the commands below
sudo ./cephadm add-repo --release $CEPH_RELEASE

# Manualy download and install the ceph trusted key
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
# Now move this new trusted key file to overwrite the file written by cephadm
# Incorrect format:
#   file /etc/apt/trusted.gpg.d/ceph.release.gpg
#   /etc/apt/trusted.gpg.d/ceph.release.gpg: PGP public key block Public-Key (old)
# Correct Format:
#   file /etc/apt/trusted.gpg
#   /etc/apt/trusted.gpg: GPG key public ring, created Tue Sep 15 20:56:41 2015
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/ceph.release.gpg

# Update to fetch the package index for ceph added above
sudo apt update

# Install ceph-common and cephadm packages
sudo ./cephadm install ceph-common
sudo ./cephadm install

sudo mkdir -p /etc/ceph
sudo ./cephadm bootstrap --mon-ip "$MONITOR_IP"

sudo ceph -v
sudo ceph status
