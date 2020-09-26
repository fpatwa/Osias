#!/bin/bash

set -euxo pipefail

SSH_PRIVATE_KEY="$1"
SSH_PUBLIC_KEY="$2"

echo -n "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

echo -n "$SSH_PUBLIC_KEY" > ~/.ssh/id_rsa.pub
echo -n "$SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys
