#!/bin/bash

cd /home/"$USER"
git clone https://github.com/openstack/refstack-client
cd refstack-client
./setup_env -t 24.0.0
# setup accounts.yml and tempest.conf
# refstack-client test -c etc/tempest.conf -v --test-list "https://refstack.openstack.org/api/v1/guidelines/2020.06/tests?target=platform&type=required&alias=true&flag=false"
