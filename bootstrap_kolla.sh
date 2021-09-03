#!/bin/bash

set -euxo pipefail

PYTHON_VERSION=$1

# Dependencies
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install python3-dev libffi-dev gcc libssl-dev python3-pip python3-venv containerd.io docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

# basedir and venv
sudo mkdir /opt/kolla
sudo chown "$USER":"$USER" /opt/kolla
cd /opt/kolla
python3 -m venv venv
source venv/bin/activate
python3 -m pip install -U pip wheel
python3 -m pip install -r "$HOME"/requirements.txt

# General Ansible config
sudo mkdir -p /etc/ansible
sudo chown "$USER":"$USER" /etc/ansible
cat > /etc/ansible/ansible.cfg <<__EOF__
[defaults]
host_key_checking=False
pipelining=True
forks=100
interpreter_python=/usr/bin/python3
__EOF__

# Kolla specific Ansible configs
cat > /opt/kolla/ansible.cfg <<__EOF__
[defaults]
strategy_plugins = /opt/kolla/venv/lib/python${PYTHON_VERSION}/site-packages/ansible_mitogen/plugins/strategy
strategy = mitogen_linear
host_key_checking=False
pipelining=True
forks=100
interpreter_python=/usr/bin/python3
ansible_python_interpreter=/usr/bin/python3
__EOF__

# Configure kolla
sudo mkdir -p /etc/kolla
sudo chown "$USER":"$USER" /etc/kolla
cp -r /opt/kolla/venv/share/kolla-ansible/etc_examples/kolla/* /etc/kolla || true
cp /opt/kolla/venv/share/kolla-ansible/ansible/inventory/* . || true

# Add nova config path
mkdir -p /etc/kolla/config/
cat > /etc/kolla/config/nova.conf <<__EOF__
[DEFAULT]
cpu_allocation_ratio = 16.0
ram_allocation_ratio = 1.5
reserved_host_memory_mb = 10240
allow_resize_to_same_host=True
scheduler_default_filters=AllHostsFilter
__EOF__


echo 'docker_apt_package: "docker.io"' >> /etc/kolla/globals.yml
