#!/bin/bash

AVAILABLE_CIDRS_FILE="/opt/gitlab-data/available_cidrs"
USED_CIDRS_FILE="/opt/gitlab-data/used_cidrs"

mapfile -t available_cidrs < <( cat $AVAILABLE_CIDRS_FILE )
if [[ -z ${available_cidrs[0]} ]]; then
  echo "No Available CIDRS were found"
  exit 1
fi
echo "${available_cidrs[0]}" >> $USED_CIDRS_FILE
sed -i "\|${available_cidrs[0]}|d" $AVAILABLE_CIDRS_FILE
echo "${available_cidrs[0]}"
