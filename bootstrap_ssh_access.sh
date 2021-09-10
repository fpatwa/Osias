#!/bin/bash

set -euxo pipefail

SSH_PRIVATE_KEY="$1"
SSH_PUBLIC_KEY="$2"

echo -n "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

echo -n "$SSH_PUBLIC_KEY" > ~/.ssh/id_rsa.pub
echo -n "$SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys

#
# Create and configure ubuntu user if it does not exist
#
user_exists(){ id "$1" &>/dev/null; }
if ! user_exists "ubuntu"; then
  # Add the ubuntu user which will be used by the deployment scripts
  sudo useradd -m -U -c "Ubuntu User" -s "/bin/bash" ubuntu
  # Create ssh keys to allow login
  sudo cp -Rp "$HOME"/.ssh /home/ubuntu/
  sudo chown -R ubuntu.ubuntu /home/ubuntu/.ssh
  # Now enable passwordless sudo for ubuntu
  echo "ubuntu ALL=(ALL) NOPASSWD: ALL" > ubuntu
  sudo cp ubuntu /etc/sudoers.d/.
fi