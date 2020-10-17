#!/usr/bin/python3

import argparse
import os
import sys
import time
import json
import utils
import setup_configs
import maas

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
        "--config",
        type=str,
        required=True,
        help="The config file in toml format defining all servers and their IPs")
    parser.add_argument(
        "--file_path",
        type=str,
        required=False,
        help="path of files to be copied from the deployment node")
    parser.add_argument(
        "--MAAS_URL",
        type=str,
        required=False,
        help="The URL of the remote API, e.g. http://example.com/MAAS/ or " +
                 "http://example.com/MAAS/api/2.0/ if you wish to specify the " +
                 "API version.")
    parser.add_argument(
        "--MAAS_API_KEY",
        type=str,
        required=False,
        help="The credentials, also known as the API key, for the remote " +
                 "MAAS server. These can be found in the user preferences page " +
                 "in the web UI; they take the form of a long random-looking " +
                 "string composed of three parts, separated by colons.")
    parser.add_argument(
        "operation",
        type=str,
        choices=['cleanup',
                 'reboot_servers',
                 'reprovision_servers',
                 'install_packages'
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
                 'complete_openstack_install',
                 'copy_files',
                 'run_command'],
        help="Operation to perform")

    args = parser.parse_args()
    print(args)

    return args

def bootstrap_networking(dict_list_of_server_ips, servers_public_ip):
    utils.run_script_on_server("bootstrap_networking.sh", servers_public_ip)
    for server in dict_list_of_server_ips:
        PUBLIC_IP = server['public']
        INTERNAL_IP = server['private']
        if server.get('data') != None:
            DATA_IP = server['data']
            if DATA_IP:
                setup_configs.setup_networking_configs(INTERNAL_IP=INTERNAL_IP, PUBLIC_IP=PUBLIC_IP, DATA_IP=DATA_IP)
            else:
                setup_configs.setup_networking_configs(INTERNAL_IP=INTERNAL_IP, PUBLIC_IP=PUBLIC_IP)
        else:
            setup_configs.setup_networking_configs(INTERNAL_IP=INTERNAL_IP, PUBLIC_IP=PUBLIC_IP)
        utils.run_script_on_server('bootstrap_networking_'+PUBLIC_IP+'.sh', PUBLIC_IP)

def cleanup(servers_public_ip, storage_nodes_public_ip):
    utils.run_script_on_server('cleanup.sh', servers_public_ip[0], args=['cleanup_master'])
    utils.run_script_on_server('cleanup.sh', storage_nodes_public_ip, args=['cleanup_storage_nodes'])
    utils.run_script_on_server('cleanup.sh', servers_public_ip, args=['cleanup_nodes'])
    utils.run_cmd_on_server('sudo -s rm -fr /home/ubuntu/*', servers_public_ip)

def bootstrap_openstack(servers_public_ip, controller_nodes, network_nodes,
                        storage_nodes, compute_nodes, monitoring_nodes):
    utils.run_script_on_server('bootstrap_kolla.sh', servers_public_ip[0])
    setup_configs.setup_kolla_configs(controller_nodes, network_nodes,  storage_nodes,
                                      compute_nodes, monitoring_nodes, servers_public_ip)
    utils.run_script_on_server('configure_kolla.sh', servers_public_ip[0])
    ssh_priv_key, ssh_public_key = utils.create_new_ssh_key()
    utils.run_script_on_server('bootstrap_ssh_access.sh', servers_public_ip, args=[ssh_priv_key, ssh_public_key])
    utils.run_script_on_server('bootstrap_openstack.sh', servers_public_ip[0])

def bootstrap_ceph(servers_public_ip, storage_nodes):
    utils.run_script_on_server('bootstrap_ceph.sh', servers_public_ip[0], args=[storage_nodes[0]])

def deploy_ceph(servers_public_ip, storage_nodes):
    setup_configs.setup_ceph_node_permisions(storage_nodes)
    utils.run_script_on_server('configure_ceph_node_permissions.sh', servers_public_ip[0])
    utils.run_script_on_server('deploy_ceph.sh', servers_public_ip[0])

def reprovision_servers(maas_url, maas_api_key, servers_public_ip):
    utils.run_cmd('maas login admin {} {}'.format(maas_url, maas_api_key))
    maas.servers(servers_public_ip).deploy()

def main():
    args = parse_args()

    if args.config:
        config = utils.parser(args.config)
        controller_nodes = config.get_server_ips(node_type="control", ip_type="private")
        network_nodes = config.get_server_ips(node_type="network", ip_type="private")
        storage_nodes = config.get_server_ips(node_type="storage", ip_type="private")
        storage_nodes_public_ip = config.get_server_ips(node_type="storage", ip_type="public")
        compute_nodes = config.get_server_ips(node_type="compute", ip_type="private")
        monitoring_nodes = config.get_server_ips(node_type="monitor", ip_type="private")
        servers_public_ip = config.get_all_public_ips()
        dict_list_of_server_ips = config.get_each_servers_ips()

        cmd = ''.join((args.operation, '.sh'))

        if args.operation == 'cleanup':
           cleanup(servers_public_ip, storage_nodes_public_ip)
        elif args.operation == 'reprovision_servers':
            if args.MAAS_URL and args.MAAS_API_KEY:
                reprovision_servers(args.MAAS_URL, args.MAAS_API_KEY, servers_public_ip)
            else:
                raise Exception(
                    'ERROR: MAAS_API_KEY and/or MAAS_URL argument not specified.\n' +
                    'If operation is specified as [reprovision_servers] then ' +
                    'the optional arguments [--MAAS_URL] and [--MAAS_API_KEY] have to be set.')
        elif args.operation == 'bootstrap_networking':
            bootstrap_networking(dict_list_of_server_ips, servers_public_ip)
        elif args.operation == 'bootstrap_ceph':
            bootstrap_ceph(servers_public_ip, storage_nodes)
        elif args.operation == 'bootstrap_openstack':
            bootstrap_openstack(servers_public_ip, controller_nodes, network_nodes,
                                storage_nodes, compute_nodes, monitoring_nodes)
        elif args.operation == 'deploy_ceph':
            deploy_ceph(servers_public_ip, storage_nodes)
        elif args.operation == 'reboot_servers':
            utils.run_cmd_on_server('sudo -s shutdown -r 1', servers_public_ip)
            utils.run_cmd_on_server('echo Server is UP!', servers_public_ip)
        elif args.operation in ['pre_deploy_openstack',
                                'deploy_openstack',
                                'post_deploy_openstack',
                                'test_setup',
                                'test_refstack',
                                'test_stress']:
            utils.run_script_on_server(cmd, servers_public_ip[0])
        elif args.operation == 'install_packages':
            utils.run_script_on_server(cmd, servers_public_ip)            
        elif args.operation == 'copy_files':
            if args.file_path:
                client = utils.create_ssh_client(servers_public_ip[0])
                client.scp_from(args.file_path)
            else:
                raise Exception(
                    'ERROR: file_path argument not specified.\n' +
                    'If operation is specified as [copy_files] then the ' +
                    'optional arguments [--file_path] has to be set.')
        elif args.operation == 'complete_openstack_install':
            utils.run_script_on_server('bootstrap_networking.sh', servers_public_ip)
            bootstrap_ceph(servers_public_ip, storage_nodes)
            bootstrap_openstack(servers_public_ip, controller_nodes, network_nodes,
                                storage_nodes, compute_nodes, monitoring_nodes)
            deploy_ceph(servers_public_ip, storage_nodes)
            utils.run_script_on_server('pre_deploy_openstack.sh', servers_public_ip[0])
            utils.run_script_on_server('deploy_openstack.sh', servers_public_ip[0])
            utils.run_script_on_server('test_setup.sh', servers_public_ip[0])
            utils.run_script_on_server('test_refstack.sh', servers_public_ip[0])
    elif args.operation == 'run_command':
        # If command is specified then only perform it
        if args.command and args.target_node:
            utils.run_cmd_on_server(args.command, args.target_node)
        else:
            raise Exception(
                'ERROR: command and target_node arguments not specified.\n' +
                'If operation is specified as [run_command] then the ' +
                'optional arguments [--command] and [--target_node] have to be set.')


if __name__ == '__main__':
    main()
