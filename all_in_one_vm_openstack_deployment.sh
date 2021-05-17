#!/bin/bash

#set -euxo pipefail
set -x pipefail

############################################
# Setup Bridge
############################################
setup_bridge () {
    ip addr

    # Get existing MAC address
    mac_address=$(grep macaddress /etc/netplan/50-cloud-init.yaml |awk '{print $2}')
    # Get the interface name (remove the ":" from the name)
    interface_name=$(grep -A 1 ethernets /etc/netplan/50-cloud-init.yaml |grep -v ethernets |awk '{print $1}')
    interface_name=${interface_name%:}

    # Copy to work with a temp file
    cp /etc/netplan/50-cloud-init.yaml /tmp/50-cloud-init.yaml
    # Now modify the temp file to add the bridge information
    echo -ne "    bridges:
        br0:
            dhcp4: true
            interfaces:
                - $interface_name
            macaddress: $mac_address
" >> /tmp/50-cloud-init.yaml

    # Now copy over the modified file in the netplan directory
    sudo mv /tmp/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml

    # Activate the updated netplan configuration
    sudo netplan generate
    sleep 2
    sudo netplan apply
    sleep 5

    # Check
    ip addr
    cat /etc/netplan/50-cloud-init.yaml
}

############################################
# Get VM Profile
############################################
get_vm_profile () {
    my_ip=$(ip -o -4 addr list br0 | awk '{print $4}' | cut -d/ -f1)
    echo $my_ip
}

############
# Main
############
setup_bridge
get_vm_profile
#
echo $(systemd-resolve --status |grep "DNS Servers")

VM_PROFILE='{"Data_CIDR": "10.100.0.0/16", "DNS_IP": "10.250.53.202"}'
VM_DEPLOYMENT_CIDR='10.30.0.90/32'
python3 -c "import json;import os;vm_profile=json.loads(os.getenv('c'));vm_profile['vm_deployment_cidr']=os.getenv('VM_DEPLOYMENT_CIDR');vm_profile_file = open('vm_profile', 'w');vm_profile_file.write(json.dumps(vm_profile));vm_profile_file.close()"
#
export VM_PROFILE=$(cat test/vm_profile)
python3 -u deploy.py create_travisci_multinode --VM_PROFILE "$VM_PROFILE"
