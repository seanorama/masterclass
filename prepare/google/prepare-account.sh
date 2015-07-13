
## Setup

#### Set zone & project
gcloud config set project siq-haas
gcloud config set compute/zone europe-west1-b

#### Create network
gcloud compute --project "siq-haas" networks create "hdp-partner-workshop" --range "10.240.0.0/16"

gcloud preview --project "siq-haas" instance-groups --zone "europe-west1-b" \
    create "hdp-partner-workshop" --network "hdp-partner-workshop"


