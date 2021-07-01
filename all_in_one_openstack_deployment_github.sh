#!/bin/bash

set -euxo pipefail

############################################
# Get VM Profile
############################################
get_vm_profile () {
    public_interface=$(route -n | awk '$1 == "0.0.0.0" {print $8}')
    my_ip=$(ip -o -4 addr list "${public_interface}" | awk '{print $4}' | cut -d/ -f1)
    echo "$my_ip"
}

############################################
# Setup Bridge
############################################
setup_bridge () {
    ip addr

    netplan_file="50-cloud-init.yaml" # "00-installer-config.yaml"
    # Get existing MAC address
    mac_address=$(grep macaddress /etc/netplan/${netplan_file} |awk '{print $2}')
    # Get the interface name (remove the ":" from the name)
    interface_name=$(grep -A 1 ethernets /etc/netplan/${netplan_file} |grep -v ethernets |awk '{print $1}')
    interface_name=${interface_name%:}
    cat /etc/netplan/${netplan_file} 
    cat /etc/hosts
    cat /etc/resolv.conf
    # Copy to work with a temp file
    cp /etc/netplan/${netplan_file} /tmp/${netplan_file}
    # Now modify the temp file to add the bridge information
    echo -ne "    bridges:
        br0:
            dhcp4: true
            interfaces:
                - $interface_name
            macaddress: $mac_address
" >> /tmp/${netplan_file}

    # Now copy over the modified file in the netplan directory
    sudo mv /tmp/${netplan_file} /etc/netplan/${netplan_file}

    # Activate the updated netplan configuration
    sudo netplan generate
    sleep 2
    sudo netplan apply
    sleep 5

    # Check
    ip addr
    cat /etc/netplan/${netplan_file}
}

############
# Main
############
my_ip=$(get_vm_profile)
setup_bridge
