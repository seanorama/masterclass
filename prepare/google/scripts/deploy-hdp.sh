#!/usr/bin/env bash

el_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1)
case ${el_version} in
  "6")
    true
  ;;
  "7")
    sudo rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  ;;
esac

sudo yum makecache
sudo yum -y install git epel-release ntpd
sudo yum -y install jq python-argparse
sudo service ntpd restart
sudo chkconfig ntpd on

git clone https://github.com/seanorama/ambari-bootstrap
cd ambari-bootstrap
sudo install_ambari_server=true ./ambari-bootstrap.sh

sudo curl -ksSL -o /etc/ambari-agent/conf/public-hostname-gcloud.sh https://raw.githubusercontent.com/GoogleCloudPlatform/bdutil/master/platforms/hdp/resources/public-hostname-gcloud.sh
sudo sed -i.bak "/\[agent\]/ a public_hostname_script=\/etc\/ambari-agent\/conf\/public-hostname-gcloud.sh" /etc/ambari-agent/conf/ambari-agent.ini
sudo chmod +x /etc/ambari-agent/conf/public-hostname-gcloud.sh
sudo service ambari-agent restart

sleep 60

cd ~/ambari-bootstrap/deploy
export ambari_services="KNOX YARN ZOOKEEPER TEZ PIG SLIDER MAPREDUCE2 HIVE HDFS HBASE"
export cluster_name=$(hostname -s)
export host_count=skip
./deploy-recommended-cluster.bash

sudo useradd -G users admin
sudo useradd -r -G users ambari
