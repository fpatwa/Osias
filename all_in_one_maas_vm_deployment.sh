#!/bin/bash

#set -euxo pipefail
set -x pipefail

############################################
# Install System Packages
############################################
install_system_packages () {
    sudo apt-get update
    sudo apt-get install -y \
            qemu-system-x86 qemu-utils \
            bridge-utils libvirt-bin libvirt-daemon-system \
            virtinst virt-manager qemu-efi qemu-kvm
    sudo systemctl is-active libvirtd
    sudo usermod -aG kvm "$(whoami)"
    sudo usermod -aG libvirt "$(whoami)"
    sudo modprobe kvm_intel
}
############################################
# Deploy MaaS
############################################
deploy_maas () {
    sudo snap install --channel=2.9/stable maas
    sudo snap install maas-test-db
    yes '' | sudo maas init region+rack --database-uri maas-test-db:/// --force
    sudo maas config --show
    sudo maas createadmin --username=admin --email=admin@example.com --password password
    sudo maas apikey --username=admin > /tmp/API_KEY_FILE
    sleep 2
    maas_url=$(sudo maas config --show | grep maas_url |cut -d'=' -f 2)
    echo "$maas_url"
    sudo maas login admin "$maas_url" "$(cat /tmp/API_KEY_FILE)"
    ssh-keygen -b 2048 -t rsa -f /tmp/sshkey -q -N ''
    sudo maas admin sshkeys create "key=$(cat /tmp/sshkey.pub)"
    sudo maas admin maas set-config name=upstream_dns value=10.250.53.202
    sudo maas admin boot-source-selections create 1 os='ubuntu' release='bionic' arches='amd64' subarches='*' labels='*'
    sudo maas admin boot-resources import
}
############################################
# Configure Virsh
############################################
configure_virsh () {
    sudo virsh net-destroy default
    sudo virsh net-dumpxml default > virsh.default.net.xml
    sudo sed -i '/<dhcp>/,/<\/dhcp>/d' virsh.default.net.xml
    sudo virsh net-create virsh.default.net.xml
}
############################################
# Create Virsh VM
############################################
create_vm () {
    local vm_name="testVM"
    sudo virt-install --name=$vm_name --description 'Test MaaS VM' --os-type=Linux --os-variant=ubuntu18.04 --ram=2048 --vcpus=2 --disk path=/var/lib/libvirt/images/$vm_name.qcow2,size=20,bus=virtio,format=qcow2 --noautoconsole --graphics=none --hvm --boot network --pxe --network network=default,model=virtio
    UUID="$(sudo virsh domuuid $vm_name)"
    MAC_ADDRESS="$(sudo virsh dumpxml $vm_name | grep 'mac address' | awk -F\' '{print $2}')"
    printf "UUID: $UUID\nMAC_ADDRESS: $MAC_ADDRESS"
}

############################################
# Check status of importing the boot images
############################################
check_boot_images_import_status() {
    rack_id=$(sudo maas admin rack-controllers read |grep system_id |awk -F\" '{print $4}' |uniq)

    while [ "$(sudo maas admin boot-resources is-importing)" == "true" ]
    do
        echo "Images are still being imported...wait 30 seconds to re-check"
        sleep 30
    done

    sudo maas admin boot-resources read
    # Now import the boot images into the rack controller
    sudo maas admin rack-controller import-boot-images "$rack_id"

    while [ $(sudo maas admin rack-controller list-boot-images $rack_id |grep status |awk -F\" '{print $4}') != "synced" ]
    do
        echo "Images are still being imported into the rack controller...wait 10 seconds to re-check"
        sleep 10
    done
    
    sudo maas admin rack-controller list-boot-images "$rack_id"
}

############################################
# Add VM to MaaS
############################################
add_vm_to_maas () {
    sudo maas admin machines create architecture=amd64 mac_addresses="$MAC_ADDRESS" power_type=virsh power_parameters_power_address=qemu+ssh://ubuntu@127.0.0.1/system power_parameters_power_id="$UUID"
}

############################
# Configure MAAS networking
############################
configure_maas_networking () {
    sudo maas admin ipranges create type=dynamic start_ip=192.168.122.100 end_ip=192.168.122.120
    primary_rack=$(sudo maas admin rack-controllers read |grep system_id |awk -F\" '{print $4}' |uniq)
    fabric_id=$(sudo maas admin subnets read | jq '.[] | select(.name == "192.168.122.0/24") | .vlan.fabric_id')
    sudo maas admin vlan update "$fabric_id" 0 dhcp_on=True primary_rack="$primary_rack"
    sudo maas admin subnet update 192.168.122.0/24 gateway_ip=192.168.122.1
}

########
# Main
########
install_system_packages
deploy_maas
configure_virsh
create_vm
# Check to ensure that boot images are imported
check_boot_images_import_status
add_vm_to_maas
configure_maas_networking
