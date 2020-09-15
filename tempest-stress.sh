#!/bin/bash

source /etc/kolla/admin-openrc.sh

cd $HOME
git clone https://github.com/openstack/tempest-stress
cd  tempest-stress
python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt
pip install -r test-requirements.txt
python setup.py install

cp $HOME/accounts.yaml $HOME/tempest-stress/etc/accounts.yaml
cp $HOME/tempest.conf $HOME/tempest-stress/etc/tempest.conf
run-tempest-stress -h
#run-tempest-stress -d 600 -a
