#!/bin/bash

set -e
set -u

cd /opt/kolla
source venv/bin/activate

kolla-genpwd
kolla-ansible -i multinode certificates
kolla-ansible -i multinode bootstrap-servers

# Enable docker group for $USER
sudo usermod -aG docker $USER
