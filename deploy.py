#!/usr/bin/python3

import argparse
import os
import sys
import time
from ssh_tool import ssh_tool


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "-i",
        "--sshkey",
        type=str,
        required=False,
        help="The path to the SSH key used to access the target node")
    parser.add_argument(
        "-c",
        "--command",
        type=str,
        required=False,
        help="The command that will be run on the target node")
    parser.add_argument(
        "-n",
        "--target_node",
        type=str,
        required=False,
        help="The target node IP address that will the specified script will run on")
    parser.add_argument(
        "operation",
        type=str,
        choices=['cleanup',
                 'bootstrap_networking',
                 'bootstrap_openstack',
                 'bootstrap_ceph',
                 'pre_deploy_openstack',
                 'deploy_ceph',
                 'deploy_openstack',
                 'post_deploy_openstack',
                 'test_setup',
                 'test_refstack',
                 'test_stress',
                 'run_command'],
        help="Operation to perform")

    args = parser.parse_args()
    print(args)

    return args

def convert_to_list(parm):
    if type(parm) is str:
        tmpList = []
        tmpList.append(parm)
        return tmpList
    return parm

def create_ssh_client(target_node):
    client = ssh_tool('ubuntu', target_node)
    if not client.check_access():
        print('Failed to connect to target node with IP {} using SSH'.format(
            target_node))
        raise Exception(
            'ERROR: Failed to connect to target node with IP {} using SSH'.format(
                target_node))
    return client

def run_script_on_server(script, servers, args=None):
    servers = convert_to_list(servers)
    for server in servers:
        client = create_ssh_client(server)
        client.scp_to(script)
        if args:
            cmd = ''.join((script, ' "', args, '"'))
        else:
            cmd = script
        client.ssh(''.join(('source ', cmd)))

def run_cmd_on_server(cmd, servers):
    servers = convert_to_list(servers)
    for server in servers:
        client = create_ssh_client(server)
        client.ssh(cmd)

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
sed -i 's/control01/{CONTROLLER_NODES}/g' multinode
sed -i '/control02/d' multinode
sed -i '/control03/d' multinode

# Update Network nodes
sed -i 's/network01/{NETWORK_NODES}/g' multinode
sed -i '/network02/d' multinode

# Update compute nodes
sed -i 's/compute01/{COMPUTE_NODES}/g' multinode

# Update monitor nodes
sed -i 's/monitoring01/{MONITORING_NODES}/' multinode

# Update storage nodes
sed -i 's/storage01/{STORAGE_NODES}/g' multinode
'''.format(CONTROLLER_NODES=CONTROLLER_NODES,
           NETWORK_NODES=NETWORK_NODES,
           COMPUTE_NODES=COMPUTE_NODES,
           MONITORING_NODES=MONITORING_NODES,
           STORAGE_NODES=STORAGE_NODES)

    with open('configure_kolla.sh', 'w') as f:
        f.write('#!/bin/bash')
        f.write('\n\n')
        f.write('set -e\n')
        f.write('set -u')
        f.write('\n\n')
        f.write(globals_file)
        f.write('\n\n')
        f.write(multinode_file)

def setup_ceph_node_permisions(storage_nodes):
    copy_keys = ''
    copy_ssh_id = ''
    add_ceph_hosts = ''
    for node in storage_nodes:
        copy_keys += ''.join(('sudo ssh ', node, ' sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys', '\n'))
        copy_ssh_id += ''.join(('sudo ssh-copy-id -f -i /etc/ceph/ceph.pub root@$(ssh ', node, ' hostname)', '\n'))
        add_ceph_hosts += ''.join(('sudo ceph orch host add $(ssh ', node, ' hostname)', '\n'))

    with open('configure_ceph_node_permissions.sh', 'w') as f:
        f.write('#!/bin/bash')
        f.write("\n\n")
        f.write('set -e\n')
        f.write('set -u')
        f.write('\n\n')
        f.write(copy_keys)
        f.write('\n\n')
        f.write(copy_ssh_id)
        f.write('\n\n')
        f.write(add_ceph_hosts)

def main():
    args = parse_args()

    servers_public_ip = ['10.245.122.30', '10.245.122.32', '10.245.122.33']

    controller_nodes = ['192.168.22.30', '192.168.22.32', '192.168.22.33']
    network_nodes = ['192.168.22.30', '192.168.22.32']
    monitoring_nodes = ['']
    storage_nodes = ['192.168.22.30', '192.168.22.32', '192.168.22.33']
    compute_nodes = ['192.168.22.33']

    cmd = ''.join((args.operation, '.sh'))

    if args.operation == 'cleanup':
        # Run command on deploy node
        run_script_on_server(cmd, servers_public_ip[0], args='cleanup_master')
        run_script_on_server(cmd, servers_public_ip, args='cleanup_nodes')
        run_cmd_on_server('sudo -s rm -fr /home/ubuntu/*', servers_public_ip)
        run_cmd_on_server('sudo -s shutdown -r 1', servers_public_ip)
        run_cmd_on_server('echo Server is UP!', servers_public_ip)
    elif args.operation == 'bootstrap_networking':
        run_script_on_server(cmd, servers_public_ip)
    elif args.operation == 'bootstrap_ceph':
        run_script_on_server(cmd, servers_public_ip[0], args=controller_nodes[0])
    elif args.operation == 'bootstrap_openstack':
        run_script_on_server('bootstrap_kolla.sh', servers_public_ip[0])
        setup_kolla_configs(controller_nodes, network_nodes,  storage_nodes,
                            compute_nodes, monitoring_nodes, servers_public_ip)
        run_script_on_server('configure_kolla.sh', servers_public_ip[0])
        run_script_on_server(cmd, servers_public_ip[0])
    elif args.operation == 'deploy_ceph':
        setup_ceph_node_permisions(storage_nodes)
        run_script_on_server('configure_ceph_node_permissions.sh', servers_public_ip[0])
        run_script_on_server(cmd, servers_public_ip[0])
    elif args.operation in ['pre_deploy_openstack',
                            'deploy_openstack',
                            'post_deploy_openstack',
                            'test_setup',
                            'test_refstack',
                            'test_stress']:
        run_script_on_server(cmd, servers_public_ip[0])
    elif args.operation == 'run_command':
        # If command is specified then only perform it
        if args.command and args.target_node:
            run_cmd_on_server(args.command, args.target_node)
        else:
            raise Exception(
                'ERROR: command and target_node arguments not specified.\n' +
                'If operation is specified as [run_command] then the ' +
                'optional arguments [--command] and [--target_node] have to be set.')


if __name__ == '__main__':
    main()
