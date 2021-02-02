#!/bin/bash

AVAILABLE_CIDRS_FILE="/opt/gitlab-data/available_cidrs"
USED_CIDRS_FILE="/opt/gitlab-data/used_cidrs"

echo ""

mapfile -t available_cidrs < <( cat $AVAILABLE_CIDRS_FILE )
echo "*** Available CIDRS ***"
for cidr in "${available_cidrs[@]}"
do
  echo "$cidr"
done

mapfile -t used_cidrs < <( cat $USED_CIDRS_FILE )
echo ""
echo "*** Used CIDRS ***"
for cidr in "${used_cidrs[@]}"
do
  echo "$cidr"
done

echo ""
