#!/usr/bin/env bash
set -o xtrace

export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}

yum makecache
yum -y -q install git epel-release ntpd screen

el_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1)
case ${el_version} in
  "6")
    sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo || true
  ;;
  "7")
    rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  ;;
esac

cd
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash
#export ambari_repo=http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos7/2.x/BUILDS/2.1.3.0-291/ambaribn.repo
#export ambari_repo=http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos${el_version}/2.x/BUILDS/2.2.0.0-1291/ambaribn.repo
~/ambari-bootstrap/ambari-bootstrap.sh
sleep 10

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then

    yum -y -q install mysql-connector-java jq python-argparse python-configobj
    ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari-change-pass admin admin ${ambari_pass}

    if [ "${deploy}" = "true" ]; then
        #hdp_version=`hdp-select status hadoop-client | sed 's/hadoop-client - \([0-9]\.[0-9]\).*/\1/'`
        hdp_version=2.3

        sleep 60
        export ambari_password="${ambari_pass}"
        export cluster_name=${stack:-mycluster}
        export host_count=${host_count:-skip}
        cd ~/ambari-bootstrap/deploy

        #export ambari_services="AMBARI_METRICS HDFS HIVE MAPREDUCE2 PIG SLIDER SPARK SQOOP TEZ YARN ZOOKEEPER"
        ./deploy-recommended-cluster.bash
        cd ~
        sleep 5

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari-configs
        ambari_wait_request_complete 1

        useradd admin
        usermod -a -G users admin
        sudo -u hdfs hadoop fs -mkdir /user/admin
        sudo -u hdfs hadoop fs -chown /user/admin

        config_proxyuser=true ~/ambari-bootstrap/extras/ambari-views/create-views.sh

        ${ambari_config_set} hive-site hive.support.concurrency "true"
        ${ambari_config_set} hive-site hive.enforce.bucketing "true"
        ${ambari_config_set} hive-site hive.exec.dynamic.partition.mode "nonstrict"
        ${ambari_config_set} hive-site hive.txn.manager "org.apache.hadoop.hive.ql.lockmgr.DbTxnManager"
        ${ambari_config_set} hive-site hive.compactor.initiator.on "true"
        ${ambari_config_set} hive-site hive.compactor.worker.threads "1"
    fi
fi

exit 0
