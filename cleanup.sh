#!/bin/bash

NODES="$@"

# Remove ansible configs
sudo rm -f /etc/ansible/ansible.cfg

# Destroy openstack and delete images
kolla-ansible -i multinode destroy --yes-i-really-really-mean-it --include-images

# Remove ceph cluster & destroy ceph partition
sudo cephadm shell -- ceph cluster fsid |& tee /tmp/cephinfo

# Grabs the fsid from the output of above
grep -oP "fsid\s+\K\w+\W\w+\W\w+\W\w+\W\w+" /tmp/cephinfo > /tmp/fsid
sudo ./cephadm rm-cluster --force --fsid "$(cat /tmp/fsid)"
sudo rm -r /etc/ceph

for node in $NODES
do
    echo ""
    echo "Working on Node [$node]"

    # This will remove: all stopped containers, all networks not used by at least one container, 
    # all volumes not used by at least one container, all dangling images, all build cache
    ssh $node sudo docker system prune --volumes --force

    # Get the last device in the device list (most likely this is the secondary disk used for ceph)
    device=$(ssh $node lsblk |grep disk |tail -1 |awk '{print $1}')
    echo "Working working on device [$device]"
    
    ssh $node sudo umount /dev/$device
    ssh $node sudo sgdisk --zap-all -- /dev/$device
    ssh $node sudo partprobe || true
    ssh $node sudo wipefs -af /dev/$device
done

echo ""
echo "Cleanup of nodes complete"
echo ""
