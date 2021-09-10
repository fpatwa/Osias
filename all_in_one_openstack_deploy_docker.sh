#!/bin/bash

set -x

OPENSTACK_RELEASE="$1"
MY_IP="$2"

! read -r -d '' MULTINODE << EOM
[control]
    [control.0]
    public = "$MY_IP"
    private = "$MY_IP"
    data = ""
[network]
    [network.0]
    public = "$MY_IP"
    private = "$MY_IP"
    data = ""
[storage]
    [storage.0]
    public = "$MY_IP"
    private = "$MY_IP"
    data = ""
[compute]
    [compute.0]
    public = "$MY_IP"
    private = "$MY_IP"
    data = ""
[monitor]
    [monitor.0]
    public = ""
    private = ""
    data = ""
[variables]
    [variables.0]
    CEPH = "False"
    VM_CIDR = "${MY_IP}/32"
    VIP_IP = "${MY_IP}/32"
    POOL_START = "${MY_IP}/32"
    POOL_END = "${MY_IP}/32"
    DNS_IP = "8.8.8.8"
    OPENSTACK_RELEASE = "$OPENSTACK_RELEASE"
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
