#!/usr/bin/env bash

mypass="BadPass#1"

## re-enable password auth
sudo sed -i.bak 's/^\(PasswordAuthentication\) no/\1 yes/' /etc/ssh/sshd_config
sudo service sshd restart

sudo yum makecache
sudo yum -y install git epel-release screen ntpd mlocate
sudo chkconfig ntpd on
sudo service ntpd restart

sudo yum -y install shellinabox mosh tmux ack jq python-argparse
sudo chkconfig shellinaboxd on
#sudo sed -i.bak 's/^\(OPTS=.*\):LOGIN/\1:SSH/' /etc/sysconfig/shellinaboxd
sudo service shellinaboxd restart

ad_host="activedirectory.$(hostname -d)"
ad_host_ip=$(ping -w 1 ${ad_host} | awk 'NR==1 {print $3}' | sed 's/[()]//g')
echo "${ad_host_ip} activedirectory.hortonworks.com ${ad_host} activedirectory" | sudo tee -a /etc/hosts

mycert=/etc/pki/ca-trust/source/anchors/activedirectory.pem
sudo curl -sSL -o ${mycert} https://gist.githubusercontent.com/seanorama/b640ee08254bb3f2e19d/raw/2ce79f3720b347ff31629e25655989c226a53f91/activedirectory.pem

## add all users to 'users' group
sudo useradd admin
sudo useradd rangeradmin
sudo useradd keyadmin
sudo useradd -r ambari
printf "${mypass}\n${mypass}" | sudo passwd --stdin student
printf "${mypass}\n${mypass}" | sudo passwd --stdin admin
printf "${mypass}\n${mypass}" | sudo passwd --stdin rangeradmin
printf "${mypass}\n${mypass}" | sudo passwd --stdin keyadmin
UID_MIN=$(awk '$1=="UID_MIN" {print $2}' /etc/login.defs)
users="$(getent passwd|awk -v UID_MIN="${UID_MIN}" -F: '$3>=UID_MIN{print $1}')"
for user in ${users}; do sudo usermod -a -G users ${user}; done

##
sudo git clone https://github.com/seanorama/ambari-bootstrap /opt/ambari-bootstrap
sudo chmod -R g+rw /opt/ambari-bootstrap
sudo chgrp -R users /opt/ambari-bootstrap

## register dynamic dns
data=$(curl -sSL http://anondns.net/api/register/$(hostname -s).aa.anondns.net/a/$(curl -4s icanhazip.com))
echo "${data}" > ~/.anondns.token
curl -X POST -d "${data}" https://c82kjcyerfcp.runscope.net
