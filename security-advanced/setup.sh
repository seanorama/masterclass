#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}
#export ambari_server_custom_script=${ambari_server_custom_script:-~/ambari-bootstrap/ambari-extras.sh}
: ${recommendation_strategy:="ALWAYS_APPLY_DONT_OVERRIDE_CUSTOM_VALUES"}
export recommendation_strategy

cd

yum makecache
yum -y -q install git epel-release ntpd screen mysql-connector-java jq python-argparse python-configobj ack


curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash

~/ambari-bootstrap/ambari-bootstrap.sh

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then
    bash -c "nohup ambari-server start" || true

    sleep 60

    ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari_change_pass admin admin ${ambari_pass}

    if [ "${deploy}" = "true" ]; then

        cd ~/ambari-bootstrap/deploy

        ## various configuration changes for demo environments, and fixes to defaults
        #"hadoop.proxyuser.HTTP.groups" : "users,hadoop-users",
        #"hadoop.proxyuser.hbase.groups" : "users,hadoop-users",
        #"hadoop.proxyuser.hcat.groups" : "users,hadoop-users",
        #"hadoop.proxyuser.hive.groups" : "users,hadoop-users",
        #"hadoop.proxyuser.knox.groups" : "users,hadoop-users",
        #"hadoop.proxyuser.oozie.groups" : "users,hadoop-users",
        #"hadoop.proxyuser.root.groups" : "users,hadoop-users",
cat << EOF > configuration-custom.json
{
  "configurations" : {
    "core-site": {
        "hadoop.proxyuser.root.users" : "admin",
        "fs.trash.interval": "4320"
    },
    "hive-interactive-env": {
        "hive.server2.tez.default.queues": "llap",
        "enable_hive_interactive": "true",
        "llap_queue_capacity": "75"
    },
    "yarn-site": {
        "yarn.acl.enable" : "true"
    },
    "hdfs-site": {
      "dfs.namenode.safemode.threshold-pct": "0.99"
    },
    "hive-site": {
        "hive.exec.compress.output": "true",
        "hive.merge.mapfiles": "true",
        "hive.server2.tez.initialize.default.sessions": "true"
    },
    "mapred-site": {
        "mapreduce.job.reduce.slowstart.completedmaps": "0.7",
        "mapreduce.map.output.compress": "true",
        "mapreduce.output.fileoutputformat.compress": "true"
    }
  }
}
EOF

        export ambari_services="${ambari_services:-"HDFS MAPREDUCE2 PIG YARN HIVE ZOOKEEPER AMBARI_METRICS SLIDER AMBARI_INFRA LOGSEARCH TEZ"}"
        export ambari_password="${ambari_pass}"
        export cluster_name=${stack:-mycluster}
        export host_count=${host_count:-skip}

        ./deploy-recommended-cluster.bash
        cd ~
        sleep 5

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari_configs
        ambari_wait_request_complete 1
    fi
fi

exit 0

