#!/bin/bash

set -e
set -u

cd /opt/kolla
source venv/bin/activate

kolla-ansible -i multinode deploy
kolla-ansible -i multinode post-deploy
