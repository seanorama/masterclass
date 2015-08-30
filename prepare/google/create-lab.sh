#!/usr/bin/env bash

set -o nounset

########
##
## lab=02 lab_prefix=lab ./create-lab.sh  ## this creates with naming '$lab02...'

lab_prefix="${lab_prefix:-sroberts}"
lab="${lab:-999}"

gcloud compute --project "siq-haas" instances create \
  "${lab_prefix}${lab}-hdp" --boot-disk-device-name "${lab_prefix}${lab}-hdp" \
  --machine-type "n1-standard-4" --image centos-6 \
  --metadata-from-file sshKeys=./metadata-sshkeys \
  --zone "europe-west1-b" --network "hdp-partner-workshop" \
  --maintenance-policy "MIGRATE" --tags "hdp-partner-workshop" \
  --boot-disk-type "pd-standard" --boot-disk-size 50GB  --no-scopes

gcloud preview --project "siq-haas" instance-groups --zone "europe-west1-b" \
  instances --group "hdp-partner-workshop" add "${lab_prefix}${lab}-hdp"

#gcloud compute --project "siq-haas" instances create \
#  "${lab_prefix}${lab}-ipa" --boot-disk-device-name "${lab_prefix}${lab}-ipa" \
#  --machine-type "n1-standard-1" --image centos-7 \
#  --metadata-from-file sshKeys=./metadata-sshkeys \
#  --zone "europe-west1-b" --network "hdp-partner-workshop" \
#  --maintenance-policy "MIGRATE" --tags "hdp-partner-workshop" \
#  --boot-disk-type "pd-standard" --boot-disk-size 50GB  --no-scopes

#gcloud preview --project "siq-haas" instance-groups --zone "europe-west1-b" \
#  instances --group "hdp-partner-workshop" add "${lab_prefix}${lab}-ipa" "${lab_prefix}${lab}-hdp"
