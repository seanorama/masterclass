#!/usr/bin/env bash

## for prepping a 1-node cluster for the security masterclass

yum makecache
yum -y -q install git epel-release ntpd
yum -y -q install jq python-argparse python-configobj

## get mysql community on el/centos7
el_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1)
case ${el_version} in
  "6")
    true
  ;;
  "7")
    rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  ;;
esac

cd
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash
source ~/ambari-bootstrap/extras/ambari_functions.sh

#mypass=masterclass
${__dir}/deploy/prep-hosts.sh
${__dir}/../ambari-bootstrap.sh

cd ${__dir}/../deploy/

cat << EOF > configuration-custom.json
{
  "configurations" : {
    "hdfs-site": {
        "dfs.replication": "1",
        "dfs.datanode.data.dir" : "/mnt/dev/xvdb/dn",
        "dfs.namenode.name.dir" : "/mnt/dev/xvdb/nn"
    },
    "yarn-site": {
        "yarn.scheduler.minimum-allocation-vcores": "1",
        "yarn.scheduler.maximum-allocation-vcores": "1",
        "yarn.scheduler.minimum-allocation-mb": "512",
        "yarn.scheduler.maximum-allocation-mb": "2048",
        "yarn.nodemanager.resource.memory-mb": "32768"
    },
    "capacity-scheduler": {
        "yarn.scheduler.capacity.maximum-am-resource-percent": "0.25"
    },
    "mapred-site": {
        "mapreduce.map.memory.mb": "2048",
        "mapreduce.reduce.memory.mb": "2048",
        "mapreduce.reduce.java.opts": "-Xmx1228m",
        "mapreduce.map.java.opts": "-Xmx1228m",
        "mapreduce.task.io.sort.mb": "859",
        "yarn.app.mapreduce.am.resource.mb" : "2048"
    },
    "hive-site": {
        "hive.tez.container.size": "2048",
        "hive.auto.convert.join.noconditionaltask.size": "536870912"
    },
    "tez-site": {
        "tez.task.resource.memory.mb": "2048",
        "tez.am.resource.memory.mb": "2048"
    },
    "core-site": {
        "hadoop.proxyuser.HTTP.groups" : "users,hadoop-users",
        "hadoop.proxyuser.HTTP.hosts" : "*",
        "hadoop.proxyuser.hbase.groups" : "users,hadoop-users",
        "hadoop.proxyuser.hbase.hosts" : "*",
        "hadoop.proxyuser.hcat.groups" : "users,hadoop-users",
        "hadoop.proxyuser.hcat.hosts" : "*",
        "hadoop.proxyuser.hive.groups" : "users,hadoop-users",
        "hadoop.proxyuser.hive.hosts" : "*",
        "hadoop.proxyuser.knox.groups" : "users,hadoop-users",
        "hadoop.proxyuser.knox.hosts" : "*",
        "hadoop.proxyuser.oozie.groups" : "users",
        "hadoop.proxyuser.oozie.hosts" : "*",
        "hadoop.proxyuser.root.groups" : "users,hadoop-users",
        "hadoop.proxyuser.root.hosts" : "*"
    }
  }
}
EOF

sleep 30

export ambari_services="KNOX YARN ZOOKEEPER TEZ PIG SLIDER MAPREDUCE2 HIVE HDFS HBASE SQOOP FLUME OOZIE SPARK"
export host_count=skip
./deploy-recommended-cluster.bash

sleep 30

source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari-change-pass admin admin BadPass#1
echo "export ambari_pass=BadPass#1" >> ~/ambari-bootstrap/extras/.ambari.conf; chmod 660 ~/ambari-bootstrap/extras/.ambari.conf
source ${__dir}/ambari_functions.sh
ambari-configs
ambari_wait_request_complete 1

sleep 10

echo "client.api.port=8081" >> /etc/ambari-server/conf/ambari.properties
ambari-server restart
ambari-agent restart
echo "export ambari_port=8081" >> ~/ambari-bootstrap/extras/.ambari.conf; chmod 660 ~/ambari-bootstrap/extras/.ambari.conf

sleep 30

usermod -a -G users ${USER}

## Generic setup
chkconfig mysqld on; service mysqld start
${__dir}/onboarding.sh
config_proxyuser=true ${__dir}/ambari-views/create-views.sh
${__dir}/configs/proxyusers.sh

cd /opt
git clone https://github.com/seanorama/masterclass
cd masterclass/sql
./labs-setup.sh

