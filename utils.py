#!/usr/bin/python3

import toml
import subprocess
from ssh import SshClient


class parser:
    def __init__(self, config):
        self.data = toml.loads(config)

    def get_server_ips(self, node_type, ip_type):
        data = self.data.get(node_type)
        ips = []
        for myips in data.values():
            ips.append(myips[ip_type])
        return ips

    def get_all_public_ips(self):
        data = self.data.keys()
        ALL_PUBLIC_IPS = []
        for my_node_type in data:
            ips = parser.get_server_ips(self, node_type=my_node_type, ip_type="public")
            ALL_PUBLIC_IPS.extend(ips)
        ALL_PUBLIC_IPS = list((dict.fromkeys(ALL_PUBLIC_IPS))) # remove duplicates from list
        ALL_PUBLIC_IPS = list(filter(None, ALL_PUBLIC_IPS))  # remove null values from list
        return ALL_PUBLIC_IPS

    def get_each_servers_ips(self):
        data = self.data.keys()
        SERVERS = []
        for my_node_type in data:
            data = self.data.get(my_node_type)
            for key, value in data.items():
                if value['public']: # Remove any empty servers
                    SERVERS.extend([value])
                    # Remove duplicate servers from the list
        SERVERS = [i for n, i in enumerate(SERVERS) if i not in SERVERS[:n]]
        return SERVERS
    
    def bool_check_ips_exist(self, node_type, ip_type):
        data = self.data.get(node_type)
        for key,value in data.items():
            if value[ip_type]:
                return True
            else:
                return False

def convert_to_list(parm):
    if type(parm) is str:
        tmpList = []
        tmpList.append(parm)
        return tmpList
    return parm

def create_ssh_client(target_node):
    client = SshClient('ubuntu', target_node)
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
            arguments = ''
            for arg in args:
                arguments += ''.join((' "', arg, '"'))
            cmd = ''.join((script, arguments))
        else:
            cmd = script

        print(cmd)
        client.ssh(''.join(('source ', cmd)))

def run_cmd_on_server(cmd, servers):
    servers = convert_to_list(servers)
    for server in servers:
        client = create_ssh_client(server)
        client.ssh(cmd)

def run_cmd(command, test=True, output=True):
    """Run the specified command"""
    print(f"\n[Command Issued]\n\t{command}\n")

    output = ''
    try:
        output = subprocess.check_output(command, stderr=subprocess.STDOUT, shell=True, executable='/bin/bash')
        if not test:
            return 0
    except subprocess.CalledProcessError as e:
        if test:
            raise Exception(e.output.decode()) from e
        else:
            print(e.output.decode())
            return e.returncode

    if output:
        print(f"\n[Command Output]\n{output.decode()}\n")

    return output

def create_new_ssh_key():
    run_cmd('rm -f deploy_id_rsa')
    run_cmd('rm -f deploy_id_rsa.pub')
    run_cmd('ssh-keygen -q -t rsa -N \'\' -f ./deploy_id_rsa')

    with open('deploy_id_rsa', 'r') as f:
        ssh_priv_key = f.read()
    with open('deploy_id_rsa.pub', 'r') as f:
        ssh_public_key = f.read()

    run_cmd('rm -f deploy_id_rsa')
    run_cmd('rm -f deploy_id_rsa.pub')

    return ssh_priv_key, ssh_public_key
