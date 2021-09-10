#!/bin/bash

set -euxo pipefail

# Add br0 bridge if it does not exist
br0_exists(){ ip addr show br0 &>/dev/null; }
if ! br0_exists; then
  sudo brctl addbr br0
  sudo brctl addif br0 eth0
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
