#!/bin/bash

set -euxo pipefail

mkdir rally
cd rally/
python3 -m venv venv
source venv/bin/activate
pip install setuptools==40.3.0
pip install rally-openstack

source /etc/kolla/admin-openrc.sh
ADMIN_PASS="$(cat /etc/kolla/admin-openrc.sh  | grep  "OS_PASSWORD=" | cut -d '=' -f2)"
AUTH_URL="$(cat /etc/kolla/admin-openrc.sh | grep "OS_AUTH_URL=" | cut -d '=' -f2)"

# Create environment
cat > env.yaml << __EOF__
---
openstack:
  auth_url: "$AUTH_URL"
  region_name: RegionOne
  https_insecure: False
  https_cacert: /etc/kolla/certificates/ca/root.crt
  users:
    - username: admin
      password: "$ADMIN_PASS"
      project_name: admin
__EOF__

rally db create
rally env create --name my_openstack --spec env.yaml
rally env check

# Create deployment
rally deployment check
rally deployment create --fromenv --name=existing
rally deployment list

# List verifiers
rally verify create-verifier --type tempest --name tempest-verifier --source https://github.com/openstack/tempest.git  --version 24.0.0
rally verify list-verifiers
wget "https://refstack.openstack.org/api/v1/guidelines/2020.06/tests?target=platform&type=required&alias=true&flag=false" -O 2020.06-test-list.txt

# Begin tempest/refstack tests.
rally verify start --load-list 2020.06-test-list.txt --concurrency 8

# References:
# https://readthedocs.org/projects/rally/downloads/pdf/latest/
# https://rally.readthedocs.io/en/3.1.0/install_and_upgrade/install.html
#
