#!/usr/bin/env bash

export PDSH_SSH_ARGS_APPEND="-l student -i ${HOME}/.ssh/student.pri.key -o ConnectTimeout=5 -o CheckHostIP=no -o StrictHostKeyChecking=no -o RequestTTY=force"
domain="europe-west1-b.siq-haas"
labs=$(echo {51..51})

type="hdp" hosts_hdp=$(for i in ${labs}; do printf "p-lab${i}-${type}.${domain},"; done)
hosts_all=${hosts_hdp}
echo ## building these hosts:

cd ~/src/masterclass/prepare/google
for i in $labs; do lab=$i ./create-lab.sh & sleep 5; done
sleep 60
gcloud compute config-ssh

## check if hosts are back up
command="uptime"
pdsh -w ${hosts_all} "${command}"

read -p "Press [Enter] key to continue"

#### 4. all hosts: set passwords, install shellinaboxd, grow root partition & reboot
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/deploy-all.sh | bash \
    ; curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/growroot.sh | bash"
pdsh -w ${hosts_all} "${command}"
sleep 60
#### 3. check all hosts
command="uptime"
pdsh -w ${hosts_all} "${command}"

read -p "Press [Enter] key to continue"


#### 5) deploy HDP (a few minutes after above to account for the reboot)
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/deploy-hdp.sh | bash"
time pdsh -w ${hosts_hdp} "${command}"
command="source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari-change-pass admin admin BadPass#1"
time pdsh -w ${hosts_hdp} "${command}"
command="echo export ambari_pass=BadPass#1 > ~/.ambari.conf; chmod 600 ~/.ambari.conf"
time pdsh -w ${hosts_hdp} "${command}"
for dest in $(echo ${hosts_hdp} | tr ',' ' '); do
  scp -o "RequestTTY=no" -i ~/.ssh/student.pri.key ~/src/masterclass/prepare/activedirectory/ambari.keytab student@${dest}:~/
done

sleep 600

command='source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari-get-cluster; ${ambari_curl}/clusters/${ambari_cluster}/requests/1 | grep request_status'
time pdsh -w ${hosts_all} "${command}"

read -p "Press [Enter] key to continue"
command="~/ambari-bootstrap/extras/add-trusted-ca.sh | bash"
time pdsh -w ${hosts_all} "${command}"

command="~/ambari-bootstrap/extras/samples/sample-data.sh; ~/ambari-bootstrap/extras/configs/proxyusers.sh"
time pdsh -w ${hosts_hdp} "${command}"

exit
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
  --allow tcp,udp --network "hdp-partner-workshop" --source-ranges "${ip}/32"
```

#### Delete instances
lab=99
gcloud compute --project siq-haas instances delete --zone "europe-west1-b" p-lab${lab}-hdp
gcloud compute --project siq-haas instances delete --zone "europe-west1-b" p-lab${lab}-ipa
