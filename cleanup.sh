#!/bin/bash

NODES="$@"


# Destroy openstack and delete images
cd /opt/kolla
source venv/bin/activate
kolla-ansible -i multinode destroy --yes-i-really-really-mean-it --include-images
deactivate
pip3 uninstall -qy python-openstackclient

# Cleanup refstack
cd ~
sudo rm -r refstack-client


# Remove ansible configs
sudo rm -f /etc/ansible/ansible.cfg

# Remove ceph cluster & destroy ceph partition
sudo cephadm shell -- ceph cluster fsid |& tee /tmp/cephinfo

# Grabs the fsid from the output of above
grep -oP "fsid\s+\K\w+\W\w+\W\w+\W\w+\W\w+" /tmp/cephinfo > /tmp/fsid
sudo ./cephadm rm-cluster --force --fsid "$(cat /tmp/fsid)"
sudo rm -r /etc/ceph

for node in $NODES
do
    echo ""
    echo "INFO: Working on Node [$node]"

    # This will remove: all stopped containers, all networks not used by at least one container, 
    # all volumes not used by at least one container, all dangling images, all build cache
    ssh $node sudo docker stop $(docker ps -aq)
    ssh $node sudo docker rm $(docker ps -aq)
    ssh $node sudo docker system prune --volumes --force -a
    ssh $node sudo rm -r /etc/kolla

    # Get the last device in the device list (most likely this is the secondary disk used for ceph)
    device=$(ssh $node lsblk |grep disk |tail -1 |awk '{print $1}')
    echo "INFO: Working working on device [$device]"

    ssh $node sudo umount /dev/$device
    ssh $node sudo sgdisk --zap-all -- /dev/$device
    ssh $node sudo partprobe || true
    ssh $node sudo wipefs -af /dev/$device
done

echo ""
echo "INFO: Cleanup of nodes complete"
echo ""
