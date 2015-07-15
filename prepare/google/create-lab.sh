#!/usr/bin/env bash

set -o nounset

########
##
## This script will create instances with name 'p-lab99-...'.
##
## Execute like this to make for other names:
## lab=02 ./create-lab.sh  ## this creates with naming 'p-lab02...'
## lab=12 ./create-lab.sh  ## this creates with naming 'p-lab12...'

lab="${lab:-99}"

gcloud compute --project "siq-haas" instances create \
  "p-lab${lab}-hdp" --boot-disk-device-name "p-lab${lab}-hdp" \
  --machine-type "n1-standard-4" --image centos-6 \
  --metadata-from-file sshKeys=./metadata-sshkeys \
  --zone "europe-west1-b" --network "hdp-partner-workshop" \
  --maintenance-policy "MIGRATE" --tags "hdp-partner-workshop" \
  --boot-disk-type "pd-standard" --boot-disk-size 50GB  --no-scopes &

gcloud compute --project "siq-haas" instances create \
  "p-lab${lab}-ipa" --boot-disk-device-name "p-lab${lab}-ipa" \
  --machine-type "n1-standard-1" --image centos-7 \
  --metadata-from-file sshKeys=./metadata-sshkeys \
  --zone "europe-west1-b" --network "hdp-partner-workshop" \
  --maintenance-policy "MIGRATE" --tags "hdp-partner-workshop" \
  --boot-disk-type "pd-standard" --boot-disk-size 50GB  --no-scopes

gcloud preview --project "siq-haas" instance-groups --zone "europe-west1-b" \
  instances --group "hdp-partner-workshop" add "p-lab${lab}-ipa" "p-lab${lab}-hdp"
