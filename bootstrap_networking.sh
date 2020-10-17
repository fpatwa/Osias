#!/bin/bash

set -euxo pipefail

sudo sh -c 'cat > /etc/rc.local <<__EOF__
#!/bin/sh -e

ip link add veno0 type veth peer name veno1
ifconfig veno0 up
ifconfig veno1 up
brctl addif br0 veno0
exit 0
__EOF__'

sudo chmod +x /etc/rc.local
sudo chmod 755 /etc/rc.local
sudo chown root:root /etc/rc.local
