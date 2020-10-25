#!/bin/bash

set -euxo pipefail

cd /opt/kolla
source venv/bin/activate

kolla-genpwd
kolla-ansible -i multinode certificates

# This bootstrap is necessary to prep for ceph and openstack deployment.
kolla-ansible -i multinode bootstrap-servers

# Enable docker group for $USER
sudo usermod -aG docker $USER
