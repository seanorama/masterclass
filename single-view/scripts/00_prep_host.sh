#!/usr/bin/env bash
set -o xtrace

cd /root
export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}

yum makecache
yum -y -q install epel-release
yum -y -q install autoconf python-crypto python-devel unzip gcc-c++ git python-argparse

git clone -b develop https://github.com/seanorama/ambari-bootstrap
~/ambari-bootstrap/extras/deploy/prep-hosts.sh
echo BadPass#1 > ~/.ambari.conf
chmod 600 ~/.ambari.conf

exit 0

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

        sleep 60

        #export ambari_services="HDFS HIVE MAPREDUCE2 PIG SLIDER SPARK TEZ YARN ZOOKEEPER ZEPPELIN NIFI"
        ./deploy-recommended-cluster.bash
        cd ~
        sleep 5

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari-configs
        ambari_wait_request_complete 1

        usermod -a -G users ${USER}
        ~/ambari-bootstrap/extras/onboarding.sh

        #useradd admin
        #usermod -a -G users admin
        #sudo -u hdfs hadoop fs -mkdir /user/admin
        #sudo -u hdfs hadoop fs -chown /user/admin

        #config_proxyuser=true ~/ambari-bootstrap/extras/ambari-views/create-views.sh

        #yum install -y lucidworks-hdpsearch
        #sudo -u hdfs hadoop fs -mkdir /user/solr
        #sudo -u hdfs hadoop fs -chown solr /user/solr
        #chown -R solr:solr /opt/lucidworks-hdpsearch/solr
        #echo ZK_HOST="localhost:2181" >> /opt/lucidworks-hdpsearch/solr/bin/solr.in.sh
        #echo SOLR_MODE=solrcloud >> /opt/lucidworks-hdpsearch/solr/bin/solr.in.sh
        #service solr start
        #chkconfig solr on

    fi
fi
