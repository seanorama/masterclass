#!/usr/bin/bash

## for prepping a 1-node cluster for the governance masterclass

sudo yum -y -q install git
cd
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash
source ~/ambari-bootstrap/extras/ambari_functions.sh

${__dir}/deploy/prep-hosts.sh

export ambari_services="YARN ZOOKEEPER TEZ OOZIE FLUME PIG SLIDER MAPREDUCE2 HIVE HDFS FALCON ATLAS SQOOP"
"${__dir}/deploy/deploy-hdp.sh"
sleep 30

source ${__dir}/ambari_functions.sh
source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari_change_pass admin admin BadPass#1
echo "export ambari_pass=BadPass#1" > ~/ambari-bootstrap/extras/.ambari.conf; chmod 660 ~/ambari-bootstrap/extras/.ambari.conf
source ${__dir}/ambari_functions.sh
ambari_configs
ambari_wait_request_complete 1

## Generic setup
sudo chkconfig mysqld on; sudo service mysqld start
${__dir}/add-trusted-ca.sh
${__dir}/onboarding.sh
#${__dir}/ambari-views/create-views.sh
config_proxyuser=true ${__dir}/ambari-views/create-views.sh
#${__dir}/samples/sample-data.sh
${__dir}/configs/proxyusers.sh
${__dir}/ranger/prep-mysql.sh
proxyusers="oozie" ${__dir}/configs/proxyusers.sh
## centos6 only #${__dir}/oozie/replace-mysql-connector.sh

sudo mkdir -p /app; sudo chown ${USER}:users /app; sudo chmod g+wx /app

mirror_host="${mirror_host:-mc-teacher1.$(hostname -d)}"
mirror_host_ip=$(ping -w 1 ${mirror_host} | awk 'NR==1 {print $3}' | sed 's/[()]//g')
echo "${mirror_host_ip} mirror.hortonworks.com ${mirror_host} mirror admin admin.hortonworks.com" | sudo tee -a /etc/hosts

${ambari_config_set} capacity-scheduler yarn.scheduler.capacity.root.default.maximum-am-resource-percent 0.5
${ambari_config_set} capacity-scheduler yarn.scheduler.capacity.maximum-am-resource-percent 0.5
${ambari_config_set} yarn-site yarn.scheduler.minimum-allocation-mb 250
#${ambari_config_set} yarn-site yarn.scheduler.maximum-allocation-mb 8704
${ambari_config_set} yarn-site "yarn.resourcemanager.webapp.proxyuser.hcat.groups"  "*"
${ambari_config_set} yarn-site "yarn.resourcemanager.webapp.proxyuser.hcat.hosts" "*"
${ambari_config_set} yarn-site "yarn.resourcemanager.webapp.proxyuser.oozie.groups" "*"
${ambari_config_set} yarn-site "yarn.resourcemanager.webapp.proxyuser.oozie.hosts" "*"
${ambari_config_set} yarn-site yarn.scheduler.minimum-allocation-vcores 1

## Governance specific setup
sudo usermod -a -G hadoop admin
${__dir}/atlas/atlas-hive-enable.sh
proxyusers="falcon flume" ${__dir}/configs/proxyusers.sh
proxyusers="falcon flume" ${__dir}/oozie/proxyusers.sh
${__dir}/falcon/bugfix_oozie-site_elexpression.sh
${ambari_config_set} oozie-site   oozie.service.AuthorizationService.security.enabled "false"

##### atlas client tutorial
## install atlas client
curl -ssLO https://github.com/seanorama/atlas/releases/download/0.1/atlas-client.tar.bz2
sudo yum -y -q install bzip2
tar -xf atlas-client.tar.bz2
sudo mv atlas-client /opt
sudo ln -sf /opt/atlas-client/bin/atlas-client /usr/local/bin/
sudo touch /application.log /audit.log; sudo chown ${USER} /application.log /audit.log

## setup source DRIVERS & TIMESHEET database in MySQL
cd
git clone https://github.com/seanorama/atlas
cd atlas/tutorial
mysql -u root < MySQLSourceSystem.sql
####


## setup falcon churn demo

mkdir /tmp/falcon-churn; cd /tmp/falcon-churn
curl -sSL -O http://hortonassets.s3.amazonaws.com/tutorial/falcon/falcon.zip
unzip falcon.zip
sudo su - hdfs -c "hadoop fs -mkdir -p /shared/falcon/demo/primary/processed/enron; hadoop fs -chmod -R 777 /shared"
sudo sudo -u admin hadoop fs -copyFromLocal demo /shared/falcon/
sudo sudo -u hdfs hadoop fs -chown -R admin:hadoop /shared/falcon
sudo sudo -u hdfs hadoop fs -chmod -R g+w /shared/falcon

(
sudo mkdir -p /opt/hadoop/samples
sudo chmod 777 /opt/hadoop/samples
cd /opt/hadoop/samples

dfs_cmd="sudo sudo -u hdfs hadoop fs"
dfs_cmd_admin="sudo sudo -u admin hadoop fs"

${dfs_cmd} -mkdir /public
${dfs_cmd} -mkdir -p /public/samples /public/secured/dir1
${dfs_cmd} -chmod -R 777 /public

## Sandbox data sets
curl -sSL -O https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/data/sample_07.csv
curl -sSL -O https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/data/sample_08.csv
${dfs_cmd_admin} -put sample_07.csv sample_08.csv /public/samples
)

