#!/bin/bash

CIDR="$1"

AVAILABLE_CIDRS_FILE="/opt/gitlab-data/available_cidrs"
USED_CIDRS_FILE="/opt/gitlab-data/used_cidrs"

sed -i "\|$CIDR|d" $USED_CIDRS_FILE
echo "$CIDR" >> "$AVAILABLE_CIDRS_FILE"

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
