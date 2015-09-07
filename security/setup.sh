#!/usr/bin/env bash

## for prepping a 1-node cluster for the security masterclass

sudo yum -y -q install git
cd
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash
source ~/ambari-bootstrap/extras/ambari_functions.sh

${__dir}/deploy/prep-hosts.sh

export ambari_services="KNOX YARN ZOOKEEPER TEZ PIG SLIDER MAPREDUCE2 HIVE HDFS HBASE"
"${__dir}/deploy/deploy-hdp.sh"
sleep 30

source ${__dir}/ambari_functions.sh
source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari-change-pass admin admin BadPass#1
echo "export ambari_pass=BadPass#1" > ~/ambari-bootstrap/extras/.ambari.conf; chmod 660 ~/ambari-bootstrap/extras/.ambari.conf
source ${__dir}/ambari_functions.sh
ambari-configs
ambari_wait_request_complete 1

## Generic setup
sudo chkconfig mysqld on; sudo service mysqld start
${__dir}/add-trusted-ca.sh
${__dir}/onboarding.sh
${__dir}/ambari-views/create-views.sh
#config_proxyuser=true ${__dir}/ambari-views/create-views.sh
${__dir}/samples/sample-data.sh
${__dir}/configs/proxyusers.sh
${__dir}/ranger/prep-mysql.sh
#proxyusers="oozie falcon" ${__dir}/configs/proxyusers.sh
##centos6 only #${__dir}/oozie/replace-mysql-connector.sh

mirror_host="${mirror_host:-mc-teacher1.$(hostname -d)}"
mirror_host_ip=$(ping -w 1 ${mirror_host} | awk 'NR==1 {print $3}' | sed 's/[()]//g')
echo "${mirror_host_ip} mirror.hortonworks.com ${mirror_host} mirror admin admin.hortonworks.com" | sudo tee -a /etc/hosts
sudo mkdir -p /app; sudo chown ${USER}:users /app; sudo chmod g+wx /app


