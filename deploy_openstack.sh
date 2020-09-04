#!/bin/bash

cd /opt/kolla
source venv/bin/activate
kolla-ansible -i multinode prechecks |& tee /home/ubuntu/prechecks.log 
kolla-ansible -i multinode pull
kolla-ansible -i multinode deploy |& tee /home/ubuntu/deploy.log
kolla-ansible -i multinode post-deploy
