#!/bin/bash

function_name=$1

function cleanup_master() {
    # Destroy openstack and delete images
    cd /opt/kolla
    source venv/bin/activate
    kolla-ansible -i multinode destroy --yes-i-really-really-mean-it --include-images
    deactivate
    sudo pip3 uninstall -qy python-openstackclient

    # Cleanup refstack
    cd ~
    sudo rm -fr refstack-client

    # Remove ansible configs
    sudo rm -f /etc/ansible/ansible.cfg

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
        systemctl stop $ceph_service
	    sleep 1
        systemctl disable $ceph_service
    done

    sudo rm -fr /etc/systemd/system/ceph*
    sudo rm -fr /etc/systemd/system/*/ceph*
    sudo rm -fr /lib/systemd/system/ceph*

    sudo systemctl daemon-reload
    sudo systemctl reset-failed

    # This will remove: all stopped containers, all networks not used by at least one container,
    # all volumes not used by at least one container, all dangling images, all build cache
    sudo docker rm -f $(docker ps -aq)
    sudo docker system prune --volumes --force -a
    sudo rm -fr /etc/kolla

    # Get the last device in the device list (most likely this is the secondary disk used for ceph)
    device=$(sudo lsblk |grep disk |tail -1 |awk '{print $1}')
    echo "INFO: Working working on device [$device]"

    sudo umount /dev/$device
    sudo sgdisk --zap-all -- /dev/$device
    sudo partprobe || true
    sudo wipefs -af /dev/$device
    # remove all logical devices that use the /dev/mapper driver
    sudo dmsetup remove_all

    # Cleanup all files/dirs in the ubuntu home directory
    #rm -fr /home/ubuntu/*
}

$function_name
