#!/bin/bash

set -x

OPENSTACK_RELEASE=$1
MY_IP="$2"

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
    CEPH = "False"
    VM_CIDR = "${my_ip}/32"
    VIP_IP = "${my_ip}/32"
    POOL_START = "${my_ip}/32"
    POOL_END = "${my_ip}/32"
    DNS_IP = "8.8.8.8"
    OPENSTACK_RELEASE = "$OPENSTACK_RELEASE"
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
python3 -u deploy.py post_deploy_openstack --config "$MULTINODE"
python3 -u deploy.py test_setup --config "$MULTINODE"
python3 -u deploy.py test_refstack --config "$MULTINODE"
