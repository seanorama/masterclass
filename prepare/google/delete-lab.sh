#!/usr/bin/env bash

set -o nounset

########
##
## This script will delet instances with name 'p-lab99-...'.
##
## Execute like this to make for other names:
## lab=02 ./create-lab.sh  ## this creates with naming 'p-lab02...'
## lab=12 ./create-lab.sh  ## this creates with naming 'p-lab12...'

lab="${lab:-99}"

gcloud compute --project siq-haas instances delete --zone "europe-west1-b" p-lab${lab}-hdp
gcloud compute --project siq-haas instances delete --zone "europe-west1-b" p-lab${lab}-ipa

gcloud preview --project "siq-haas" instance-groups --zone "europe-west1-b" \
  instances --group "hdp-partner-workshop" remove "p-lab${lab}-ipa" "p-lab${lab}-hdp"
