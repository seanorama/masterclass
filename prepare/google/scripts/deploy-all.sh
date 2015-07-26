#!/usr/bin/env bash

## re-enable password auth
#sudo sed -i.bak 's/^\(PasswordAuthentication\) no/\1 yes/' /etc/ssh/sshd_config
#sudo service sshd restart

sudo yum makecache
sudo yum -y install epel-release screen

sudo yum -y install shellinabox mosh tmux pdcp ack
sudo chkconfig shellinaboxd on
#sudo sed -i.bak 's/^\(OPTS=.*\):LOGIN/\1:SSH/' /etc/sysconfig/shellinaboxd
sudo service shellinaboxd restart

pass="BadPass#1"
printf "${pass}\n${pass}" | sudo passwd --stdin student
sudo usermod -a -G users student

ad_host="activedirectory.$(hostname -d)"
ad_host_ip=$(ping -w 1 ${ad_host} | awk 'NR==1 {print $3}' | sed 's/[()]//g')
echo "${ad_host_ip} activedirectory.hortonworks.com ${ad_host} activedirectory" | sudo tee -a /etc/hosts

mycert=/etc/pki/ca-trust/source/anchors/activedirectory.pem
sudo curl -sSL -o ${mycert} https://gist.githubusercontent.com/seanorama/b640ee08254bb3f2e19d/raw/2ce79f3720b347ff31629e25655989c226a53f91/activedirectory.pem

## register dynamic dns
data=$(curl -sSL http://anondns.net/api/register/$(hostname -s).aa.anondns.net/a/$(curl -4s icanhazip.com))
echo "${data}" > ~/.anondns.token
curl -X POST -d "${data}" https://c82kjcyerfcp.runscope.net
