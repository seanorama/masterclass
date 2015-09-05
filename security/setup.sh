#!/usr/bin/bash

## for prepping a 1-node cluster for the security masterclass

## magic, don't touch
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
source ${__dir}/../ambari_functions.sh

${__dir}/deploy/prep-hosts.sh

export ambari_services="KNOX YARN ZOOKEEPER TEZ PIG SLIDER MAPREDUCE2 HIVE HDFS HBASE"
${__dir}/deploy/deploy-hdp.sh

source ${__dir}/ambari_functions.sh
ambari-configs
sudo chkconfig mysqld on; sudo service mysqld start
source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari-change-pass admin admin BadPass#1
echo export ambari_pass=BadPass#1 > ~/.ambari.conf; chmod 600 ~/.ambari.conf
echo export ambari_pass=BadPass#1 > ~/ambari-bootstrap/extras/.ambari.conf; chmod 660 ~/ambari-bootstrap/extras/.ambari.conf
source ${__dir}/ambari_functions.sh
ambari-configs

sudo mkdir -p /app; sudo chown ${USER}:users /app; sudo chmod g+wx /app

${__dir}/add-trusted-ca.sh
${__dir}/onboarding.sh
${__dir}/ambari-views/create-views.sh
${__dir}/samples/sample-data.sh
${__dir}/configs/proxyusers.sh
${__dir}/ranger/prep-mysql.sh
#config_proxyuser=true ${__dir}/ambari-views/create-views.sh

exit


