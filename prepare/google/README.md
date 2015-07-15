# Scripts for prepping the workshop on Google Compute

Todo: translate to ansible for easier management

## Deploy process

#### 0. Set variables

```
export PDSH_SSH_ARGS_APPEND="-l student -i ${HOME}/.ssh/student.pri.key -o ConnectTimeout=5 -o CheckHostIP=no -o StrictHostKeyChecking=no -o RequestTTY=force"
domain="europe-west1-b.siq-haas"
labs=$(echo {10..15})
```

#### 1. Create instances

```
cd ~/src/masterclass/prepare/google
for i in $labs; do lab=$i ./create-lab.sh & sleep 5; done
```

```
#### 2. Build inventory
gcloud compute config-ssh
type="hdp" hosts_hdp=$(for i in ${labs}; do printf "p-lab${i}-${type}.${domain},"; done)
type="ipa" hosts_ipa=$(for i in ${labs}; do printf "p-lab${i}-${type}.${domain},"; done)
hosts_all=${hosts_hdp}${hosts_ipa}

#### 3. check all hosts
command="whoami"
pdsh -w ${hosts_all} "${command}"

#### 4. all hosts: set passwords, install shellinaboxd, grow root partition & reboot
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/deploy-all.sh | bash"
pdsh -w ${hosts_all} "${command}"
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/growroot.sh | bash"
pdsh -w ${hosts_all} "${command}"

#### 3. check all hosts
command="echo pong"
pdsh -w ${hosts_all} "${command}"


#### 5) deploy IPA (can be run in parallel with 5a)
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/deploy-ipa.sh | bash ; curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/ipa/sample-data.sh | bash"
pdsh -w ${hosts_ipa} "${command}" &
#### 5) deploy HDP (a few minutes after above to account for the reboot)
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/deploy-hdp.sh | bash"
pdsh -w ${hosts_hdp} "${command}"
##### prepare environment
#command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/ipa/sample-data.sh | bash"
#pdsh -w ${hosts_ipa} "${command}" 

#### 6) deploy IPA to HDP node (after above completes)
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/deploy-hdp-ipa.sh | bash"
pdsh -w ${hosts_hdp} "${command}"

#### prepare hadoop
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/hadoop/sample-data.sh | bash"
pdsh -w ${hosts_hdp} "${command}"



```

#### ...) Delete lab

```
for i in $labs; do lab=$i ./delete-lab.sh; done
```

---------------

## General commands

SSH: `gcloud compute ssh p-lab04-ipa`

#### List instances

```
gcloud compute instances list --project siq-haas --regexp p-lab.*
```

#### Whitelist current IP

```
ip=$(curl -4 icanhazip.com)
gcloud compute --project "siq-haas" firewall-rules create "source-$(echo ${ip} | tr '.' '-')" \
  --allow tcp udp --network "hdp-partner-workshop" --source-ranges "${ip}/32"
```

#### Delete instances
lab=99
gcloud compute --project siq-haas instances delete --zone "europe-west1-b" p-lab${lab}-hdp
gcloud compute --project siq-haas instances delete --zone "europe-west1-b" p-lab${lab}-ipa
