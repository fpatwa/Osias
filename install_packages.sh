#!/bin/bash

set -euxo pipefail

sudo apt-get update

DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y

#DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends \
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
    bridge-utils \
    libffi-dev \
    gcc \
    libssl-dev \
    python3-dev \
    python3-pip \
    python3-venv \
    libapt-pkg-dev

sudo apt-get autoremove -y
