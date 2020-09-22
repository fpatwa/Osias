#!/bin/bash

set -e
set -u

sudo apt-get install bridge-utils -qqy

sudo sh -c 'cat > /etc/rc.local <<__EOF__
#!/bin/sh -e

ip link add veno0 type veth peer name veno1
ifconfig veno0 up
ifconfig veno1 up
brctl addif br0 veno0
exit 0
__EOF__'


sudo sh -c 'cat > /etc/netplan/01-netcfg.yaml <<__EOF__
network:
        version: 2
        renderer: networkd
        ethernets:
                eno1:
                        dhcp4: no
                        addresses: [INTERNALIP/24]
__EOF__'

sudo sh -c 'cat > /etc/netplan/02-netcfg.yaml <<__EOF__
network:
        version: 2
        renderer: networkd
        ethernets:
                eno2:
                         dhcp4: no
        bridges:
                br0:
                         interfaces: [eno2]
                         addresses: [PUBLICIP/24]
                         gateway4: MYGATEWAY
                         mtu: 1500
                         nameservers:
                                 addresses: [10.250.53.202]
__EOF__'

INTERNALIP=$(/sbin/ifconfig eno1 | grep 'inet ' | awk '{print $2}')
PUBLICIP=$(/sbin/ifconfig eno2 | grep 'inet ' | awk '{print $2}')
# IF PUBLICIP is null, check for br0
[ -z "$PUBLICIP" ] && PUBLICIP=$(/sbin/ifconfig br0 | grep 'inet ' | awk '{print $2}')
        
MYGATEWAY=$(ip r | grep ^default | awk '{print $3}')

sudo sed -i "s/INTERNALIP/$INTERNALIP/" /etc/netplan/01-netcfg.yaml
sudo sed -i "s/MYGATEWAY/$MYGATEWAY/" /etc/netplan/02-netcfg.yaml
sudo sed -i "s/PUBLICIP/$PUBLICIP/" /etc/netplan/02-netcfg.yaml

sudo chmod +x /etc/rc.local
sudo chmod 755 /etc/rc.local
sudo chown root:root /etc/rc.local
sudo chown root:root /etc/netplan/01-netcfg.yaml
sudo chown root:root /etc/netplan/02-netcfg.yaml
sudo chmod 644 /etc/netplan/01-netcfg.yaml
sudo chmod 644 /etc/netplan/02-netcfg.yaml
# if file does not exist, exit happy.
sudo rm -f /etc/netplan/50-cloud-init.yaml
