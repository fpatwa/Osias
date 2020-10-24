#!/bin/bash

set -euxo pipefail

cd /opt/kolla
source venv/bin/activate

kolla-ansible -i multinode bootstrap-servers
kolla-ansible -i multinode deploy
kolla-ansible -i multinode post-deploy
