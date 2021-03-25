#!/bin/bash

#set -euxo pipefail
set -x pipefail

############################################
# Setup Bridge
############################################
setup_bridge () {
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
    sudo netplan apply
}

setup_bridge

