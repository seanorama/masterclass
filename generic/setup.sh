#!/usr/bin/env bash
set -o xtrace

export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}

yum makecache
yum -y -q install git epel-release ntpd screen mysql-connector-java jq python-argparse python-configobj

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

~/ambari-bootstrap/extras/deploy/prep-hosts.sh

#export ambari_repo=http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos${el_version}/2.x/BUILDS/2.2.0.0-1291/ambaribn.repo
~/ambari-bootstrap/ambari-bootstrap.sh
sleep 10

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then

    if [ "${deploy}" = "true" ]; then
        #hdp_version=`hdp-select status hadoop-client | sed 's/hadoop-client - \([0-9]\.[0-9]\).*/\1/'`
        hdp_version=2.3

        ## zeppelin
        git clone https://github.com/hortonworks-gallery/ambari-zeppelin-service.git /var/lib/ambari-server/resources/stacks/HDP/${hdp_version}/services/ZEPPELIN
        sed -i.bak '/dependencies for all/a \    "ZEPPELIN_MASTER-START": ["NAMENODE-START", "DATANODE-START"],' /var/lib/ambari-server/resources/stacks/HDP/${hdp_version}/role_command_order.json
        echo "host all all 127.0.0.1/32 md5" >> /var/lib/pgsql/data/pg_hba.conf
        service postgresql restart

        ## solr
        git clone https://github.com/abajwa-hw/solr-stack.git /var/lib/ambari-server/resources/stacks/HDP/${hdp_version}/services/SOLR
        sed -i.bak '/dependencies for all/a \    "SOLR-START" : ["ZOOKEEPER_SERVER-START"],' /var/lib/ambari-server/resources/stacks/HDP/${hdp_version}/role_command_order.json

        ## nifi
        git clone https://github.com/abajwa-hw/ambari-nifi-service.git   /var/lib/ambari-server/resources/stacks/HDP/${hdp_version}/services/NIFI

        ps aux | grep ambari-server | grep java | awk '{print $2}' | xargs kill
        sleep 5
        if ! nohup sh -c "ambari-server start 2>&1 > /dev/null"; then
            printf 'Ambari Server failed to start\n' >&2
        fi
        if ! nohup sh -c "ambari-agent restart 2>&1 > /dev/null"; then
            printf 'Ambari Agent failed to start\n' >&2
        fi

        sleep 60

        ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
        ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari-change-pass admin admin ${ambari_pass}

        cd ~/ambari-bootstrap/deploy

        ## various configuration changes for demo environments, and fixes to defaults
cat << EOF > configuration-custom.json
{
  "configurations" : {
    "hdfs-site": {
        "dfs.replication": "1"
    },
    "yarn-site": {
        "yarn.scheduler.minimum-allocation-vcores": "1",
        "yarn.scheduler.maximum-allocation-vcores": "1",
        "yarn.scheduler.minimum-allocation-mb": "256",
        "yarn.scheduler.maximum-allocation-mb": "2048"
    },
    "hive-site": {
        "hive.support.concurrency": "true",
        "hive.enforce.bucketing": "true",
        "hive.exec.dynamic.partition.mode": "nonstrict",
        "hive.txn.manager": "org.apache.hadoop.hive.ql.lockmgr.DbTxnManager",
        "hive.compactor.initiator.on": "true",
        "hive.compactor.worker.threads": "1"
    },
    "solr-config": {
        "solr.download.location": "HDPSEARCH",
        "solr.znode": "/solr",
        "solr.cloudmode": "true"
    },
    "kafka-broker": {
        "listeners": "PLAINTEXT://0.0.0.0:6667"
    },
    "zeppelin-ambari-config": {
        "zeppelin.executor.mem": "512m",
        "zeppelin.executor.instances": "2",
        "zeppelin.install.dir": "/opt"
    }
    core-site": {
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

        export ambari_password="${ambari_pass}"
        export cluster_name=${stack:-mycluster}
        export host_count=${host_count:-skip}

        ./deploy-recommended-cluster.bash
        cd ~
        sleep 5

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari-configs
        ambari_wait_request_complete 1

        usermod -a -G users ${USER}
        ~/ambari-bootstrap/extras/onboarding.sh

    fi
fi

exit 0
