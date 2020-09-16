#!/bin/bash

ssh 192.168.22.30 sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
ssh 192.168.22.32 sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
ssh 192.168.22.33 sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys

ssh-copy-id -f -i /etc/ceph/ceph.pub root@r2-610-32
ssh-copy-id -f -i /etc/ceph/ceph.pub root@r2-610-33

./cephadm shell -- ceph orch host add r2-610-32
./cephadm shell -- ceph orch host add r2-610-33

./cephadm shell -- ceph orch host ls
sleep 30
./cephadm shell -- ceph orch device ls --refresh
./cephadm shell -- ceph orch apply osd --all-available-devices

ceph osd pool create volumes
sudo ./cephadm shell -- rbd pool init volumes

ceph osd pool create images
sudo ./cephadm shell -- rbd pool init images

ceph osd pool create backups
sudo ./cephadm shell -- rbd pool init backups

ceph osd pool create vms
sudo ./cephadm shell -- rbd pool init vms

#ceph osd pool create metrics
#sudo ./cephadm shell -- rbd pool init metrics
#sudo ./cephadm shell -- ceph auth get-or-create client.gnocchi mon 'profile rbd' osd 'profile rbd pool=metrics' mgr 'profile rbd pool=metrics'

# Get cinder-backup ready
sudo mkdir -p /etc/kolla/config/cinder/cinder-backup
sudo chown -R ubuntu:ubuntu /etc/kolla/config/
cp /etc/ceph/ceph.conf /etc/kolla/config/cinder/cinder-backup/ceph.conf
sudo ./cephadm shell -- ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'
./cephadm shell -- ceph auth get-or-create client.cinder > /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder.keyring
./cephadm shell -- ceph auth get-or-create client.cinder-backup >  /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder-backup.keyring
sed -i $'s/\t//g' /etc/kolla/config/cinder/cinder-backup/ceph.conf
sed -i $'s/\t//g' /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder.keyring
sed -i $'s/\t//g' /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder-backup.keyring

# Get cinder-volume ready
sudo mkdir -p /etc/kolla/config/cinder/cinder-volume
sudo chown -R ubuntu:ubuntu /etc/kolla/config/
sudo ./cephadm shell -- ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
cp /etc/ceph/ceph.conf /etc/kolla/config/cinder/cinder-volume/ceph.conf
./cephadm shell -- ceph auth get-or-create client.cinder > /etc/kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring
sed -i $'s/\t//g' /etc/kolla/config/cinder/cinder-volume/ceph.conf
sed -i $'s/\t//g' /etc/kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring

# Get glance ready
sudo mkdir -p /etc/kolla/config/glance
sudo chown -R ubuntu:ubuntu /etc/kolla/config/
cp /etc/ceph/ceph.conf /etc/kolla/config/glance/ceph.conf
sudo ./cephadm shell -- ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
./cephadm shell -- ceph auth get-or-create client.glance > /etc/kolla/config/glance/ceph.client.glance.keyring
sed -i $'s/\t//g' /etc/kolla/config/glance/ceph.conf
sed -i $'s/\t//g' /etc/kolla/config/glance/ceph.client.glance.keyring

# Get nova ready
sudo mkdir -p /etc/kolla/config/nova
sudo chown -R ubuntu:ubuntu /etc/kolla/config/
cp /etc/ceph/ceph.conf /etc/kolla/config/nova/ceph.conf
./cephadm shell -- ceph auth get-or-create client.cinder > /etc/kolla/config/nova/ceph.client.cinder.keyring
sed -i $'s/\t//g' /etc/kolla/config/nova/ceph.conf
sed -i $'s/\t//g' /etc/kolla/config/nova/ceph.client.cinder.keyring

# Get Gnocchi ready
#sudo mkdir -p  /etc/kolla/config/gnocchi
#sudo chown -R ubuntu:ubuntu /etc/kolla/config/
#cp /etc/ceph/ceph.conf /etc/kolla/config/gnocchi/ceph.conf
#./cephadm shell -- ceph auth get-or-create client.gnocchi  > /etc/kolla/config/gnocchi/ceph.client.gnocchi.keyring
#sed -i $'s/\t//g' /etc/kolla/config/gnocchi/ceph.conf
#sed -i $'s/\t//g' /etc/kolla/config/gnocchi/ceph.client.gnocchi.keyring
