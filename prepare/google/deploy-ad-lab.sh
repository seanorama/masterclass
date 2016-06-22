#!/usr/bin/env bash

export PDSH_SSH_ARGS_APPEND="-l student -i ${HOME}/.ssh/student.pri.key -o ConnectTimeout=5 -o CheckHostIP=no -o StrictHostKeyChecking=no -o RequestTTY=force"
export domain="europe-west1-b.siq-haas"
export lab_prefix=p-test
export labs=$(echo {005..005})

type="hdp" hosts_hdp=$(for i in ${labs}; do printf "${lab_prefix}${i}-${type}.${domain},"; done)
export hosts_all=${hosts_hdp}

echo "Creating these hosts:"
for host in ${hosts_all}; do printf "   %s\n" "${host}"; done
read -p "Continue?"

cd ~/src/masterclass/prepare/google
for i in $labs; do lab=$i ./create-lab.sh & sleep 5; done
sleep 60
gcloud compute config-ssh

command="uptime"
pdsh -w ${hosts_all} "${command}"
read -p "Press [Enter] key to continue"
command="uptime"
pdsh -w ${hosts_all} "${command}"
read -p "Press [Enter] key to continue"

#### 4. all hosts: set passwords, install shellinaboxd, grow root partition & reboot
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/deploy-all.sh | bash \
  ; sudo /opt/ambari-bootstrap/providers/growroot.sh; sudo reboot"
pdsh -w ${hosts_all} "${command}"
sleep 60

command="uptime"
pdsh -w ${hosts_all} "${command}"
read -p "Press [Enter] key to continue"
command="uptime"
pdsh -w ${hosts_all} "${command}"
read -p "Press [Enter] key to continue"


#### 5) deploy HDP (a few minutes after above to account for the reboot)
command="curl https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/deploy-hdp.sh | bash"
time pdsh -w ${hosts_hdp} "${command}"
command="source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari_change_pass admin admin BadPass#1"
time pdsh -w ${hosts_hdp} "${command}"
#command="echo export ambari_pass=BadPass#1 > ~/.ambari.conf; chmod 600 ~/.ambari.conf"
#time pdsh -w ${hosts_hdp} "${command}"
for dest in $(echo ${hosts_hdp} | tr ',' ' '); do
  scp -o "RequestTTY=no" -i ~/.ssh/student.pri.key ~/src/masterclass/prepare/activedirectory/ambari.keytab student@${dest}:~/
done

sleep 600
command='source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari_get_cluster; ${ambari_curl}/clusters/${ambari_cluster}/requests/1 | grep request_status'
time pdsh -w ${hosts_hdp} "${command}"
read -p "Press [Enter] key to continue"
command='source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari_get_cluster; ${ambari_curl}/clusters/${ambari_cluster}/requests/1 | grep request_status'
time pdsh -w ${hosts_hdp} "${command}"
read -p "Press [Enter] key to continue"
command='source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari_get_cluster; ${ambari_curl}/clusters/${ambari_cluster}/requests/1 | grep request_status'
time pdsh -w ${hosts_hdp} "${command}"
read -p "Press [Enter] key to continue"
command='source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari_get_cluster; ${ambari_curl}/clusters/${ambari_cluster}/requests/1 | grep request_status'
time pdsh -w ${hosts_hdp} "${command}"
read -p "Press [Enter] key to continue"


command="sudo chkconfig mysqld on; sudo service mysqld start"
time pdsh -w ${hosts_hdp} "${command}"
command="~/ambari-bootstrap/extras/add-trusted-ca.sh"
time pdsh -w ${hosts_all} "${command}"
command="~/ambari-bootstrap/extras/samples/sample-data.sh; ~/ambari-bootstrap/extras/configs/proxyusers.sh"
time pdsh -w ${hosts_hdp} "${command}"


exit

