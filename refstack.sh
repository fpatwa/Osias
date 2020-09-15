#!/bin/bash

source /etc/kolla/admin-openrc.sh

git clone https://github.com/openstack/refstack-client
cd refstack-client
./setup_env -t 24.0.0

cp $HOME/accounts.yaml $HOME/refstack-client/etc/accounts.yaml
cp $HOME/tempest.conf $HOME/refstack-client/etc/tempest.conf

source $HOME/refstack-client/.venv/bin/activate
refstack-client test -c etc/tempest.conf -v -- --regex tempest.api.identity.v3.test_tokens.TokensV3Test.test_create_token
#refstack-client test -c etc/tempest.conf -v --test-list "https://refstack.openstack.org/api/v1/guidelines/2020.06/tests?target=platform&type=required&alias=true&flag=false"
