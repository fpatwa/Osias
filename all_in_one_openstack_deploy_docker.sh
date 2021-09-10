#!/bin/bash

set -x

OPENSTACK_RELEASE=$1

############################################
# Get VM Profile
############################################
get_vm_profile () {
    public_interface=$(route -n | awk '$1 == "0.0.0.0" {print $8}')
    my_ip=$(ip -o -4 addr list "${public_interface}" | awk '{print $4}' | cut -d/ -f1)
    echo "$my_ip"
}

############
# Main
############
my_ip=$(get_vm_profile)

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
# Deploy openstack using kolla
#
pip3 install toml timeout_decorator
python3 -u deploy.py bootstrap_networking --config "$MULTINODE"
python3 -u deploy.py bootstrap_openstack --config "$MULTINODE"
python3 -u deploy.py pre_deploy_openstack --config "$MULTINODE"
python3 -u deploy.py deploy_openstack --config "$MULTINODE"
python3 -u deploy.py post_deploy_openstack --config "$MULTINODE"
python3 -u deploy.py test_setup --config "$MULTINODE"
python3 -u deploy.py test_refstack --config "$MULTINODE"
