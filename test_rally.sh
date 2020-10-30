#!/bin/bash

set -euxo pipefail

mkdir rally
cd rally/
python3 -m venv venv
source venv/bin/activate
pip install setuptools==40.3.0 wheel==0.34.1 requests==2.22.0
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

rally db ensure
rally env create --name my_openstack --spec env.yaml
rally env check

# Create deployment
rally deployment check
rally deployment create --fromenv --name=existing
rally deployment list

#rally task validate

# List verifiers
rally verify create-verifier --type tempest --name tempest-verifier --source https://github.com/openstack/tempest.git  --version 24.0.0
rally verify list-verifiers
wget "https://refstack.openstack.org/api/v1/guidelines/2020.06/tests?target=platform&type=required&alias=true&flag=false" -O 2020.06-test-list.txt


cat > refstack.conf << __EOF__
[auth]
create_isolated_networks = True

[compute]
min_compute_nodes = 3
min_microversion = 2.1
max_microversion = 2.87
# max_microversion = 2.79
endpoint_type = publicURL
fixed_network_name = mynet

[compute-feature-enabled]
validation.run_validation = True
live_migration = True
live_migrate_paused_instances = True
preserve_ports = True
console_output = True
resize = True
attach_encrypted_volume = False
pause = True
shelve = True
suspend = True
cold_migration = True
vnc_console = True

[identity]
catalog_type = identity

[identity-feature-enabled]
api_v2 = False
api_v3 = True

[image]
image_path = https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
http_image = https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

[network-feature-enabled]
ipv6_subnet_attributes = False
ipv6 = False

[object-storage]
region = RegionOne
endpoint_type = internal

[object-storage-feature-enabled]
discoverability = True

[validation]
auth_method = keypair
ip_version_for_ssh = 4
network_for_ssh = public
security_group = True
security_group_rules = True
image_ssh_password = gocubsgo

__EOF__

rally verify configure-verifier --reconfigure --extend refstack.conf
rally verify configure-verifier  --show

# Begin refstack certification (233) tests.
rally verify start --load-list 2020.06-test-list.txt

UUID="$(rally verify list | grep tempest-verifier | awk '{print $2}')"
rally verify report "$UUID" --type html --to /home/ubuntu/report.html

# Begin rally (1000+) tests 
#rally verify start

# References:
# https://readthedocs.org/projects/rally/downloads/pdf/latest/
# https://rally.readthedocs.io/en/3.1.0/install_and_upgrade/install.html
#
