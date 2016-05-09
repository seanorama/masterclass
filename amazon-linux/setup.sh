#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}
export ambari_server_custom_script=${ambari_server_custom_script:-~/ambari-bootstrap/ambari-extras.sh}
export ambari_repo_baseurl=http://dev.hortonworks.com.s3.amazonaws.com/ambari
export ambari_version=2.4.0.0

cd

yum makecache
yum -y -q install git

git clone -b release/v2.2.2.0 http://github.com/seanorama/ambari-bootstrap

exit 0

~/ambari-bootstrap/extras/deploy/prep-hosts.sh

~/ambari-bootstrap/ambari-bootstrap.sh

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then
    bash -c "nohup ambari-server start" || true

    sleep 60

    ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari-change-pass admin admin ${ambari_pass}

    if [ "${deploy}" = "true" ]; then

        cd ~/ambari-bootstrap/deploy

        ## various configuration changes for demo environments, and fixes to defaults
cat << EOF > configuration-custom.json
{
  "configurations" : {
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
        "zeppelin.executor.instances": "2"
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
