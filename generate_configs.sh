#!/bin/bash

NODES="$@"

for node in $NODES
do
    cat >> jobs-config.yml <<__EOF__
server-$node:
  script:
    - echo "Running job for server [$node]"
__EOF__
done