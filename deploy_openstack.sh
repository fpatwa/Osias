#!/bin/bash

set -euxo pipefail

cd /opt/kolla
source venv/bin/activate

sudo apt update
kolla-ansible -i multinode deploy
kolla-ansible -i multinode post-deploy
