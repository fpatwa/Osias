
# Dependencies
sudo apt-get update
sudo apt-get -y install python3-dev libffi-dev gcc libssl-dev python3-pip python3-venv

# basedir and venv
sudo mkdir /opt/kolla
sudo chown $USER:$USER /opt/kolla
cd /opt/kolla
python3 -m venv venv
. venv/bin/activate
pip install -U pip
pip install -U 'ansible<2.10'
pip install kolla-ansible

# Ansible config
sudo mkdir /etc/ansible
sudo chown $USER:$USER /etc/ansible
cat >>/etc/ansible/ansible.cfg <<__EOF__
[defaults]
host_key_checking=False
pipelining=True
forks=100
interpreter_python=/usr/bin/python3
__EOF__

# Fix: python_apt broken/old on pypi
git clone https://salsa.debian.org/apt-team/python-apt/ -b 1.8.6
cd python-apt
sudo apt-get -y install libapt-pkg-dev
python setup.py install
cd ..

# Configure kolla
sudo mkdir -p /etc/kolla
sudo chown $USER:$USER /etc/kolla
cp -r /opt/kolla/venv/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
cp /opt/kolla/venv/share/kolla-ansible/ansible/inventory/* .

# Globals file is completely commented out besides these variables.
cat >>/etc/kolla/globals.yml <<__EOF__
kolla_base_distro: "centos"
kolla_install_type: "source"
openstack_release: "ussuri"
kolla_internal_vip_address: "192.168.22.250"
kolla_external_vip_address: "10.245.122.250"
network_interface: "eno1"
kolla_external_vip_interface: "br0"
neutron_external_interface: "veno1"
kolla_enable_tls_internal: "yes"
kolla_enable_tls_external: "yes"
kolla_copy_ca_into_containers: "yes"
kolla_verify_tls_backend: "no"
kolla_enable_tls_backend: "yes"
openstack_cacert: /etc/pki/tls/certs/ca-bundle.crt
enable_cinder: "yes"
enable_cinder_backend_lvm: "no"
ceph_nova_user: "cinder"
glance_backend_ceph: "yes"
glance_backend_swift: "no"
cinder_backend_ceph: "yes"
cinder_backup_driver: "ceph"
nova_backend_ceph: "yes"
__EOF__

# Update multinode file
# Update control nodes
sed -i 's/control01/192.168.22.33/g' multinode
sed -i 's/control02/192.168.22.32/g' multinode
sed -i 's/control03/192.168.22.30/g' multinode

# Update Network nodes
sed -i 's/network01/192.168.22.30/g' multinode
sed -i 's/network02/192.168.22.32/g' multinode

# Update compute nodes
sed -i 's/compute01/192.168.22.33/g' multinode

# Update monitor nodes
sed -i 's/monitoring01//' multinode

# Update storage nodes
sed -i 's/storage01/192.168.22.30\n192.168.22.32\n192.168.22.33/g' multinode
# ansible -i multinode all -m ping


kolla-genpwd
kolla-ansible -i multinode certificates
kolla-ansible -i multinode bootstrap-servers
sudo groupadd docker
sudo usermod -aG docker $USER
