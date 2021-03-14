#!/bin/bash

#set -euxo pipefail
set -x pipefail

#sudo apt update
#sudo apt install -y snap snapd
sudo snap install --channel=2.9/stable maas
sudo snap install maas-test-db
yes '' | sudo maas init region+rack --database-uri maas-test-db:/// --force
sudo maas config --show
sudo maas createadmin --username=admin --email=admin@example.com --password password
sudo maas apikey --username=admin > /tmp/API_KEY_FILE

sleep 2

maas_url=$(sudo maas config --show | grep maas_url)
echo $maas_url

sudo maas login admin "$maas_url"/api/2.0 - < /tmp/API_KEY_FILE
ssh-keygen -b 2048 -t rsa -f /tmp/sshkey -q -N ''
sudo maas admin sshkeys create "key=$(cat /tmp/sshkey.pub)"
sudo maas admin maas set-config name=upstream_dns value=10.250.53.202
sudo maas admin boot-source-selections create 1 os='ubuntu' release='bionic' arches='amd64' subarches='*' labels='*'
sudo maas admin boot-resources import

sudo maas admin boot-resources is-importing

#        print("Images are still importing...")
#        print("Import is complete")
