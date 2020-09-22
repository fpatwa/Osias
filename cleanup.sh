#!/bin/bash

function_name=$1

function cleanup_master() {
    # Destroy openstack and delete images
    cd /opt/kolla
    python3 -m venv venv
    source venv/bin/activate
    kolla-ansible -i multinode destroy --yes-i-really-really-mean-it --include-images
    deactivate
    sudo pip3 uninstall -qy python-openstackclient

    # Cleanup refstack
    cd ~
    sudo rm -fr refstack-client

    # Cleanup kolla and ansible directories
    sudo rm -fr /etc/kolla /etc/ansible /opt/kolla

    # Get all the fsids
    fsids=$(sudo cephadm ls |grep fsid |cut -d"\"" -f 4|uniq)

    # Remove ceph cluster & destroy ceph partition
    for id in $fsids;do sudo ./cephadm rm-cluster --force --fsid $id;done
    sudo rm -fr /etc/ceph
}

function cleanup_nodes() {
    # ceph services cleanup
    ceph_services=$(sudo systemctl |grep ceph |grep "\.service" |awk '{print $2}')
    for ceph_service in $ceph_services
    do
        sudo systemctl stop $ceph_service
        sleep 1
        sudo systemctl disable $ceph_service
    done

    sudo rm -fr /etc/systemd/system/ceph*
    sudo rm -fr /etc/systemd/system/*/ceph*
    sudo rm -fr /lib/systemd/system/ceph*

    sudo systemctl daemon-reload
    sudo systemctl reset-failed

    # This will remove: all stopped containers, all networks not used by at least one container,
    # all volumes not used by at least one container, all dangling images, all build cache
    sudo docker rm -f $(sudo docker ps -aq)
    sudo docker system prune --volumes --force -a

    # Get the last device in the device list (most likely this is the secondary disk used for ceph)
    device=$(sudo lsblk |grep disk |tail -1 |awk '{print $1}')
    echo "INFO: Working working on device [$device]"

    sudo umount /dev/$device
    sudo sgdisk --zap-all -- /dev/$device
    sudo partprobe || true
    sudo wipefs -af /dev/$device
    # remove all logical devices that use the /dev/mapper driver
    sudo dmsetup remove_all

    # Cleanup kolla dirs
    sudo rm -fr /etc/kolla /opt/kolla
}

$function_name
