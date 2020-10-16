#!/bin/bash

set -euxo pipefail

source /etc/kolla/admin-openrc.sh

MYDNS="10.250.53.202"

openstack role create ResellerAdmin

# Create tempest admin users.
openstack user create tempest_01 --password tempest_01
openstack project create --enable tempest_01
openstack role add admin --user tempest_01 --project tempest_01

openstack user create tempest_02 --password tempest_02
openstack project create --enable tempest_02
openstack role add admin --user tempest_02 --project tempest_02

# Create tempest reseller_admin users.
openstack user create tempest_03 --password tempest_03
openstack project create --enable tempest_03
openstack role add ResellerAdmin --user tempest_03 --project tempest_03

openstack user create tempest_04 --password tempest_04
openstack project create --enable tempest_04
openstack role add ResellerAdmin --user tempest_04 --project tempest_04

openstack user create tempest_05 --password tempest_05
openstack project create --enable tempest_05
openstack role add member --user tempest_05 --project tempest_05

openstack user create tempest_06 --password tempest_06
openstack project create --enable tempest_06
openstack role add member --user tempest_06 --project tempest_06

#TENANT=$(openstack project list -f value -c ID --user swiftop)
#openstack network create --project "${TENANT}" mynet
#openstack subnet create --project "${TENANT}" --subnet-range 192.168.100.0/24 --dns-nameserver "${MYDNS}" --network mynet mysubnet
#openstack router create --enable --project "${TENANT}" myrouter
#openstack router add subnet myrouter mysubnet

git clone https://github.com/openstack/refstack-client
cd refstack-client
./setup_env -t 24.0.0

cp $HOME/accounts.yaml $HOME/refstack-client/etc/accounts.yaml
cp $HOME/tempest.conf $HOME/refstack-client/etc/tempest.conf

source $HOME/refstack-client/.venv/bin/activate
#refstack-client test -c etc/tempest.conf -v -- --regex tempest.api.identity.v3.test_tokens.TokensV3Test.test_create_token
refstack-client test -c etc/tempest.conf -v --test-list "https://refstack.openstack.org/api/v1/guidelines/2020.06/tests?target=platform&type=required&alias=true&flag=false"
