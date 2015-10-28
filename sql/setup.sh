#!/usr/bin/env bash

## for prepping a 1-node cluster for the security masterclass

sudo yum makecache
sudo yum -y -q install git epel-release ntpd
sudo yum -y -q install jq python-argparse python-configobj

## get mysql community on el/centos7
el_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1)
case ${el_version} in
  "6")
    true
  ;;
  "7")
    sudo rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  ;;
esac

cd
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash
source ~/ambari-bootstrap/extras/ambari_functions.sh

#mypass=masterclass
${__dir}/deploy/prep-hosts.sh

cd ${__dir}/../deploy/

cat << EOF > configuration-custom.json
{
  "configurations" : {
      "hdfs-site": {
        "dfs.replication": "1",
        "dfs.datanode.data.dir" : "/mnt/dev/xvdb/dn,/mnt/dev/xvdc/dn",
        "dfs.namenode.name.dir" : "/mnt/dev/xvdb/nn,/mnt/dev/xvdc/nn"
      }
  }
}
EOF

export ambari_services="KNOX YARN ZOOKEEPER TEZ PIG SLIDER MAPREDUCE2 HIVE HDFS HBASE SQOOP FLUME OOZIE SPARK"
export cluster_name="${cluster_name:-$(hostname -s)}"
export host_count=skip
./deploy-recommended-cluster.bash

sleep 30

source ${__dir}/ambari_functions.sh
source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari-change-pass admin admin BadPass#1
echo "export ambari_pass=BadPass#1" > ~/ambari-bootstrap/extras/.ambari.conf; chmod 660 ~/ambari-bootstrap/extras/.ambari.conf
source ${__dir}/ambari_functions.sh
ambari-configs
ambari_wait_request_complete 1

sudo usermod -a -G users ${USER}

## Generic setup
sudo chkconfig mysqld on; sudo service mysqld start
${__dir}/onboarding.sh
${__dir}/ambari-views/create-views.sh
config_proxyuser=true ${__dir}/ambari-views/create-views.sh
${__dir}/configs/proxyusers.sh

