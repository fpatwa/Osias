#!/bin/bash

set -euxo pipefail

# Copy files necessary for both:
sudo cp /etc/kolla/certificates/ca/root.crt "$HOME"/root.crt
sudo chown "$USER":"$USER" "$HOME"/root.crt

# Create accounts and tempest files:
source /etc/kolla/admin-openrc.sh
openstack flavor create --id 100 --vcpus 1 --ram 1024 --swap 1024 --disk 10 ref.nano
openstack flavor create --id 101 --vcpus 2 --ram 2048 --swap 1024 --disk 20 ref.micro

ADMIN_PASS="$(cat /etc/kolla/admin-openrc.sh  | grep  "OS_PASSWORD=" | cut -d '=' -f2)"
CIRROSID="$(openstack image list -f value -c ID --name CirrOS)"
CIRROSID2="$(openstack image list -f value -c ID --name CirrOS-2)"
PUBLICNETWORKID="$(openstack network list --external -c ID -f value)"
PUBLICNETWORKNAME="$(openstack network list --external -c Name -f value)"
URILINKV2="$(openstack endpoint list --service identity --interface public -c URL -f value)/v2.0"
URILINKV3="$(openstack endpoint list --service identity --interface public -c URL -f value)/v3"
REGION="$(openstack region list -c Region -f value)"

cat > $HOME/accounts.yaml <<__EOF__
- password: tempest_01
  project_name: tempest_01
  username: tempest_01
  types:
    - admin
  roles:
    - admin

- password: tempest_02
  project_name: tempest_02
  username: tempest_02
  types:
    - admin
  roles:
    - admin
#
# reseller_admin
#
- password: tempest_03
  project_name: tempest_03
  username: tempest_03
  types:
    - reseller_admin
  roles:
    - ResellerAdmin
- password: tempest_04
  project_name: tempest_04
  username: tempest_04
  types:
    - reseller_admin
  roles:
    - ResellerAdmin
#
# member
#
- password: tempest_05
  project_name: tempest_05
  username: tempest_05
  roles:
    - member
- password: tempest_06
  project_name: tempest_06
  username: tempest_06
  roles:
    - member
__EOF__


cat > $HOME/tempest.conf <<__EOF__
[DEFAULT]
debug = False
use_stderr = False
log_file = $HOME/Tempest.log

[identity]
catalog_type = identity
disable_ssl_certificate_validation = False
ca_certificates_file = $HOME/root.crt
uri = $URILINKV2
uri_v3 = $URILINKV3
auth_version = v3
region = $REGION
v3_endpoint_type = publicURL

[identity-feature-enabled]
api_v2 = False
api_v3 = True
#api_extensions = s3tokens,OS-EP-FILTER,OS-TRUST,OS-REVOKE,OS-ENDPOINT-POLICY,OS-INHERIT,OS-PKI,OS-OAUTH1,OS-SIMPLE-CERT,OS-FEDERATION,OS-EC2

#[scenario]
#img_dir = etc
#img_file = cirros-0.4.0-x86_64-disk.img

[auth]
# tempest_roles = admin
use_dynamic_credentials = False
test_accounts_file = $HOME/refstack-client/etc/accounts.yaml
default_credentials_domain_name = Default
create_isolated_networks = True
admin_username = admin
admin_project_name = admin
admin_password = $ADMIN_PASS
admin_domain_name = Default

[object-storage]
region = $REGION
operator_role = Member
reseller_admin_role = ResellerAdmin
endpoint_type = internal

[object-storage-feature-enabled]
discoverability = True

[oslo-concurrency]
lock_path = /tmp

[compute]
min_compute_nodes = 3
min_microversion = 2.1
max_microversion = 2.79
flavor_ref = 100
flavor_ref_alt = 101
image_ref = $CIRROSID
image_ref_alt = $CIRROSID2
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

#[network-feature-enabled]
#ipv6_subnet_attributes = false
#api_extensions = address-scope,router-admin-state-down-before-update,agent,agent-resources-synced,allowed-address-pairs,auto-allocated-topology,availability_zone,availability_zone_filter,default-subnetpools,dhcp_agent_scheduler,dvr,empty-string-filtering,external-net,extra_dhcp_opt,extraroute,extraroute-atomic,filter-validation,fip-port-details,flavors,floatingip-pools,ip-substring-filtering,router,ext-gw-mode,l3-ha,l3-flavors,l3-port-ip-change-not-allowed,l3_agent_scheduler,metering,multi-provider,net-mtu,net-mtu-writable,network_availability_zone,network-ip-availability,pagination,port-mac-address-regenerate,binding,binding-extended,port-security,project-id,provider,quotas,quota_details,rbac-policies,rbac-security-groups,revision-if-match,standard-attr-revisions,router_availability_zone,port-security-groups-filtering,security-group,service-type,sorting,standard-attr-description,subnet_onboard,subnet-service-types,subnet_allocation,subnetpool-prefix-ops,standard-attr-tag,standard-attr-timestamp

[image]
image_path = https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
http_image = https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

#[image-feature-enabled]
#api_v1 = False
#api_v2 = True

#[volume-feature-enabled]
#api_v2 = True
#backup = True
#api_v3 = True
#api_extensions = OS-SCH-HNT,os-vol-image-meta,os-volume-type-access,os-quota-sets,os-vol-mig-status-attr,os-quota-class-sets,os-volume-unmanage,scheduler-stats,os-extended-snapshot-attributes,os-volume-transfer,os-snapshot-manage,os-snapshot-unmanage,os-volume-manage,backups,consistencygroups,encryption,os-types-extra-specs,os-snapshot-actions,os-vol-host-attr,os-extended-services,cgsnapshots,os-hosts,os-vol-tenant-attr,os-volume-encryption-metadata,os-admin-actions,os-volume-actions,os-used-limits,os-services,os-types-manage,os-availability-zone,qos-specs,capabilities,OS-SCH-HNT,os-vol-image-meta,os-volume-type-access,os-quota-sets,os-vol-mig-status-attr,os-quota-class-sets,os-volume-unmanage,scheduler-stats,os-extended-snapshot-attributes,os-volume-transfer,os-snapshot-manage,os-snapshot-unmanage,os-volume-manage,backups,consistencygroups,encryption,os-types-extra-specs,os-snapshot-actions,os-vol-host-attr,os-extended-services,cgsnapshots,os-hosts,os-vol-tenant-attr,os-volume-encryption-metadata,os-admin-actions,os-volume-actions,os-used-limits,os-services,os-types-manage,os-availability-zone,qos-specs,capabilities

[service_available]
aodh = False
barbican = False
ceilometer = False
cinder = True
designate = False
glance = True
gnocchi = False
heat = True
horizon = False
ironic = False
manila = False
mistral = False
neutron = True
nova = True
octavia = False
panko = False
sahara = False
swift = False
#swift = True
trove = False
zaqar = False

[validation]
image_ssh_user = cirros
run_validation = True
connect_method = floating
auth_method = keypair
ip_version_for_ssh = 4
network_for_ssh = $PUBLICNETWORKNAME
security_group = True
security_group_rules = True
image_ssh_password = gocubsgo

#[volume]
#backend_names = block
#min_microversion = 3.0
#max_microversion = 3.59
#volume_size = 1

[network]
public_network_id = $PUBLICNETWORKID
floating_network_name = $PUBLICNETWORKNAME

[heat_plugin]
minimal_instance_type = 100
instance_type = 101
minimal_image_ref = $CIRROSID
image_ref = $CIRROSID
__EOF__
