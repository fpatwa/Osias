#!/usr/bin/python3


def setup_kolla_configs(controller_nodes, network_nodes, storage_nodes,
                        compute_nodes, monitoring_nodes, servers_public_ip):
    internal_subnet = '.'.join((controller_nodes[0].split('.')[:3]))
    kolla_internal_vip_address = '.'.join((internal_subnet, '250'))

    external_subnet = '.'.join((servers_public_ip[0].split('.')[:3]))
    kolla_external_vip_address = '.'.join((external_subnet, '250'))

    globals_file = '''
# Globals file is completely commented out besides these variables.
cat >>/etc/kolla/globals.yml <<__EOF__
# Basic Options
kolla_base_distro: "centos"
kolla_install_type: "source"
openstack_release: "ussuri"
kolla_internal_vip_address: "{kolla_internal_vip_address}"
kolla_external_vip_address: "{kolla_external_vip_address}"
network_interface: "eno1"
kolla_external_vip_interface: "br0"
neutron_external_interface: "veno1"
kolla_enable_tls_internal: "yes"
kolla_enable_tls_external: "yes"
kolla_copy_ca_into_containers: "yes"
kolla_verify_tls_backend: "no"
kolla_enable_tls_backend: "yes"
openstack_cacert: /etc/pki/tls/certs/ca-bundle.crt
enable_cinder: "yes"
enable_cinder_backend_lvm: "no"
ceph_nova_user: "cinder"
glance_backend_ceph: "yes"
glance_backend_swift: "no"
cinder_backend_ceph: "yes"
cinder_backup_driver: "ceph"
nova_backend_ceph: "yes"

# Recommended Global Options:
enable_mariabackup: "yes"
enable_neutron_agent_ha: "yes"
glance_enable_rolling_upgrade: "yes"

# Desired Global Options:
#enable_aodh: "yes"
#enable_prometheus: "yes"
#enable_ceilometer: "yes"
#enable_panko: "yes"
#enable_neutron_metering: "yes"

#enable_telegraf: "yes"
#enable_watcher: "yes"

#enable_gnocchi: "yes
#ceph_gnocchi_pool_name: "metrics"
#gnocchi_backend_storage: "ceph"
#gnocchi_incoming_storage: "{{{{ 'redis' if enable_redis | bool else '' }}}}"

#enable_central_logging: "yes"
#enable_grafana: "yes"

#enable_skydive: "yes"
__EOF__
'''.format(kolla_internal_vip_address=kolla_internal_vip_address,
           kolla_external_vip_address=kolla_external_vip_address)

    CONTROLLER_NODES = '\\n'.join(controller_nodes)
    NETWORK_NODES = '\\n'.join(network_nodes)
    COMPUTE_NODES = '\\n'.join(compute_nodes)
    MONITORING_NODES = '\\n'.join(monitoring_nodes)
    STORAGE_NODES = '\\n'.join(storage_nodes)

    multinode_file = '''
cd /opt/kolla

# Update multinode file
# Update control nodes
sed -i 's/^control01/{CONTROLLER_NODES}/g' multinode
sed -i '/^control02/d' multinode
sed -i '/^control03/d' multinode

# Update Network nodes
sed -i 's/^network01/{NETWORK_NODES}/g' multinode
sed -i '/^network02/d' multinode

# Update compute nodes
sed -i 's/^compute01/{COMPUTE_NODES}/g' multinode

# Update monitor nodes
sed -i 's/^monitoring01/{MONITORING_NODES}/' multinode

# Update storage nodes
sed -i 's/^storage01/{STORAGE_NODES}/g' multinode

'''.format(CONTROLLER_NODES=CONTROLLER_NODES,
           NETWORK_NODES=NETWORK_NODES,
           COMPUTE_NODES=COMPUTE_NODES,
           MONITORING_NODES=MONITORING_NODES,
           STORAGE_NODES=STORAGE_NODES)

    with open('configure_kolla.sh', 'w') as f:
        f.write('#!/bin/bash')
        f.write('\n\n')
        f.write('set -euxo pipefail')
        f.write('\n\n')
        f.write(globals_file)
        f.write('\n\n')
        f.write(multinode_file)

def setup_ceph_node_permisions(storage_nodes):
    copy_keys = ''
    copy_ssh_id = ''
    add_ceph_hosts = ''
    for node in storage_nodes:
        copy_keys += ''.join(('ssh -o StrictHostKeyChecking=no ', node, ' sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys', '\n'))
        copy_ssh_id += ''.join(('ssh-copy-id -f -i /etc/ceph/ceph.pub -o StrictHostKeyChecking=no root@$(ssh -o StrictHostKeyChecking=no ', node, ' hostname)', '\n'))
        add_ceph_hosts += ''.join(('sudo ceph orch host add $(ssh -o StrictHostKeyChecking=no ', node, ' hostname) ', node, '\n'))

    with open('configure_ceph_node_permissions.sh', 'w') as f:
        f.write('#!/bin/bash')
        f.write("\n\n")
        f.write('set -euxo pipefail')
        f.write('\n\n')
        f.write(copy_keys)
        f.write('\n\n')
        f.write(copy_ssh_id)
        f.write('\n\n')
        f.write(add_ceph_hosts)
