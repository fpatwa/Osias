#!/bin/bash

set -euxo pipefail

source /etc/kolla/admin-openrc.sh

cd "$HOME"
git clone https://github.com/openstack/tempest-stress
cd  tempest-stress
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -r test-requirements.txt
python setup.py install

mkdir -p  "$HOME"/tempest-stress/etc
cp "$HOME"/accounts.yaml "$HOME"/tempest-stress/etc/accounts.yaml
cp "$HOME"/tempest.conf "$HOME"/tempest-stress/etc/tempest.conf

# Run the stress test for 10 min (600 sec)
run-tempest-stress -d 600 -a
