#!/bin/bash

set -euxo pipefail

source /etc/kolla/admin-openrc.sh

MYDNS="10.250.53.202"

openstack role create ResellerAdmin

openstack user create swiftop --password a_big_secret
openstack project create --enable openstack
openstack role add Member --user swiftop --project openstack
openstack role add ResellerAdmin --user swiftop --project openstack

TENANT=$(openstack project list -f value -c ID --user swiftop)
openstack network create --project "${TENANT}" mynet
openstack subnet create --project "${TENANT}" --subnet-range 192.168.100.0/24 --dns-nameserver "${MYDNS}" --network mynet mysubnet
openstack router create --enable --project "${TENANT}" myrouter
openstack router add subnet myrouter mysubnet

git clone https://opendev.org/osf/refstack-client.git
cd refstack-client
./setup_env -t 24.0.0

cp "$HOME"/accounts.yaml "$HOME"/refstack-client/etc/accounts.yaml
cp "$HOME"/tempest.conf "$HOME"/refstack-client/etc/tempest.conf

source .venv/bin/activate
#refstack-client test -c etc/tempest.conf -v -- --regex tempest.api.identity.v3.test_tokens.TokensV3Test.test_create_token
refstack-client test -c etc/tempest.conf -v --test-list "https://refstack.openstack.org/api/v1/guidelines/2020.06/tests?target=platform&type=required&alias=true&flag=false"