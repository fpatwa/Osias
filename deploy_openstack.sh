#!/bin/bash

set -euxo pipefail
CEPH_RELEASE=$1

sudo apt-get update | grep Err |& tee /tmp/updates || true
CMD="$(cat /tmp/updates)"
if [[ "$CMD" == *"ceph"* ]]; then
   echo "CEPH ERROR"
   sudo ./cephadm add-repo --release "$CEPH_RELEASE"
elif [[  "$CMD" == *docker* ]]; then
   echo "DOCKER ERROR"
   sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   echo \
   "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi
rm -f /tmp/updates

cd /opt/kolla
source venv/bin/activate
kolla-ansible -i multinode bootstrap-servers
kolla-ansible -i multinode deploy
kolla-ansible -i multinode post-deploy
deactivate nondestructive

# Install the openstack client
python3 -m pip install -U pip wheel
python3 -m pip install python-openstackclient
