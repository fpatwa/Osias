#!/bin/bash

set -euxo pipefail

# Add br0 bridge if it does not exist
br0_exists(){ ip addr show br0 &>/dev/null; }
if ! br0_exists; then
  public_interface=$(route -n | awk '$1 == "0.0.0.0" {print $8}')
  MY_IP=$(ip -o -4 addr list "${public_interface}" | awk '{print $4}')
  MY_GATEWAY=$(ip route show 0.0.0.0/0 dev eth0 | cut -d\  -f3)
  #
  ip link add br0 type bridge
  ip link set eth0 master br0
  ip link set br0 up
  ip addr add $MY_IP dev br0
  #
  route add -net 0.0.0.0 gw $MY_GATEWAY dev br0
  ip route del default via $MY_GATEWAY dev eth0
  ip a
fi

sudo sh -c "cat > /etc/rc.local <<__EOF__
#!/bin/sh -e

ip a | grep -Eq ': veno1.*state UP' || sudo ip link add veno0 type veth peer name veno1
ip link set veno0 up
ip link set veno1 up
ip link set veno0 master br0
exit 0
__EOF__"

sudo chmod +x /etc/rc.local
sudo chmod 755 /etc/rc.local
sudo chown root:root /etc/rc.local
sudo /etc/rc.local
