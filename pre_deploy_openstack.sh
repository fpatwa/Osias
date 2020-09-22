#!/bin/bash

set -e
set -u

cd /opt/kolla
source venv/bin/activate
 
kolla-ansible -i multinode prechecks
kolla-ansible -i multinode pull
