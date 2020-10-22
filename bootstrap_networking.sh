#!/bin/bash

set -euxo pipefail

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
