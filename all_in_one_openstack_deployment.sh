#!/bin/bash

set -x

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

! read -r -d '' MULTINODE << EOM
[control]
    [control.0]
    public = "$my_ip"
    private = "$my_ip"
    data = ""
[network]
    [network.0]
    public = "$my_ip"
    private = "$my_ip"
    data = ""
[storage]
    [storage.0]
    public = "$my_ip"
    private = "$my_ip"
    data = ""
[compute]
    [compute.0]
    public = "$my_ip"
    private = "$my_ip"
    data = ""
[monitor]
    [monitor.0]
    public = ""
    private = ""
    data = ""
[variables]
    [variables.0]
    RAID = false
    CEPH = "False"
    VM_CIDR = "${my_ip}/32"
    VIP_IP = "${my_ip}/32"
    POOL_START = "${my_ip}/32"
    POOL_END = "${my_ip}/32"
    DNS_IP = "8.8.8.8"
EOM

#
# Create and configure ubuntu user
#
# Create ssh keys
ssh-keygen -t rsa -f "$HOME"/.ssh/id_rsa -C "All in one key" -N ""
cat "$HOME"/.ssh/id_rsa.pub > "$HOME"/.ssh/authorized_keys
# Add the ubuntu user which will be used by the deployment scripts
sudo useradd -m -U -c "Ubuntu User" -s "/bin/bash" ubuntu
# Create ssh keys to allow login
sudo cp -Rp "$HOME"/.ssh /home/ubuntu/
sudo chown -R ubuntu.ubuntu /home/ubuntu/.ssh
# Now enable passwordless sudo for ubuntu
echo "ubuntu ALL=(ALL) NOPASSWD: ALL" > ubuntu
sudo cp ubuntu /etc/sudoers.d/.

#
# Deploy openstack using kolla
#
pip3 install toml timeout_decorator
python3 -u deploy.py bootstrap_networking --config "$MULTINODE"
python3 -u deploy.py bootstrap_openstack --config "$MULTINODE"
python3 -u deploy.py pre_deploy_openstack --config "$MULTINODE"
python3 -u deploy.py deploy_openstack --config "$MULTINODE"
