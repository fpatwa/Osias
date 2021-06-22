#!/bin/bash

set -euxo pipefail
#set -x pipefail

pip3 install toml timeout_decorator

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

############################################
# Get VM Profile
############################################
public_interface=$(route -n | awk '$1 == "0.0.0.0" {print $8}')

get_vm_profile () {
    my_ip=$(ip -o -4 addr list ${public_interface} | awk '{print $4}' | cut -d/ -f1)
    echo "$my_ip"
}

############
# Main
############
my_ip=$(get_vm_profile)
setup_bridge
#
#my_dns=$(systemd-resolve --status |grep "DNS Servers"|awk '{print $3}')
#
#export VM_PROFILE="{\"Data_CIDR\": \"10.100.0.0/16\", \"DNS_IP\": \"$my_dns\"}"
#export VM_DEPLOYMENT_CIDR="${my_ip}/32"
#export VM_IP="${my_ip}"
#python3 -c "import json;import os;vm_profile=json.loads(os.getenv('VM_PROFILE'));vm_profile['vm_deployment_cidr']=os.getenv('VM_DEPLOYMENT_CIDR');vm_profile['vm_ip']=os.getenv('VM_IP');vm_profile_file = open('vm_profile', 'w');vm_profile_file.write(json.dumps(vm_profile));vm_profile_file.close()"
#
#export VM_PROFILE=$(cat vm_profile)
pwd
ls -la
chmod +x bootstrap_kolla.sh
cp -r * "$HOME"
"$HOME"/bootstrap_kolla.sh

#ls /opt/kolla/venv/share/kolla-ansible/etc_examples/kolla/
cp "$HOME"/virtualenv/python3.6.10/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
cp "$HOME"/virtualenv/python3.6.10/share/kolla-ansible/ansible/inventory/all-in-one .

ip a | grep -Eq ': veno1.*state UP' || sudo ip link add veno0 type veth peer name veno1
sudo ip link set veno0 up
sudo ip link set veno1 up
sudo ip link set veno0 master br0

cat >> /etc/kolla/globals.yml <<__EOF__
kolla_base_distro: "centos"
kolla_install_type: "source"
openstack_release: "ussuri"

enable_haproxy: "no"
enable_neutron_agent_ha: "no"

kolla_internal_vip_address: "${my_ip}"
kolla_external_vip_address: "${my_ip}"

network_interface: "br0"
kolla_external_vip_interface: "br0"
neutron_external_interface: "veno1"
__EOF__

ip a
cat /etc/kolla/globals.yml

sudo truncate -s0 /etc/hostname
sudo hostnamectl set-hostname localhost

#kolla-ansible -i ./multinode prechecks
kolla-genpwd
kolla-ansible -i all-in-one certificates
kolla-ansible -i all-in-one bootstrap-servers
kolla-ansible -i all-in-one prechecks

# cat /etc/hosts
# getent hosts $(hostname)
# sudo sed -i '/127.0.1.1/d' /etc/hosts
# cat /etc/hosts

# echo net.ipv4.ip_nonlocal_bind=1 >> /etc/sysctl.conf
# sudo /bin/su -c "echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.conf"
# sudo sysctl -p

kolla-ansible -i all-in-one pull
kolla-ansible -i all-in-one deploy

#sleep 300

#python3 -u deploy.py create_travisci_multinode --VM_PROFILE "$VM_PROFILE"
