#!/usr/bin/env bash
set -o xtrace

########################################################################
########################################################################
## variables

export HOME=${HOME:-/root}
export TERM=xterm
: ${ambari_pass:="BadPass#1"}
ambari_password="${ambari_pass}"
: ${stack:="mycluster"}
: ${cluster_name:=${stack}}
: ${ambari_services:="HDFS MAPREDUCE2 PIG YARN HIVE ZOOKEEPER AMBARI_METRICS SLIDER AMBARI_INFRA TEZ KAFKA SPARK ZEPPELIN HBASE SMARTSENSE"}
: ${install_ambari_server:=true}
: ${ambari_stack_version:=2.6}
: ${deploy:=true}
: ${host_count:=skip}
: ${recommendation_strategy:="ALWAYS_APPLY_DONT_OVERRIDE_CUSTOM_VALUES"}

## overrides
#export ambari_repo=https://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.5.0.3/ambari.repo

export install_ambari_server ambari_pass host_count ambari_services
export ambari_password cluster_name recommendation_strategy
export ambari_stack_version

########################################################################
########################################################################
##
cd

yum makecache
yum -y -q install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum clean cache
yum -y -q install git ntpd screen mysql-connector-java jq python-argparse python-configobj ack postgresql-jdbc
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash

########################################################################
########################################################################
~/ambari-bootstrap/extras/deploy/prep-hosts.sh
~/ambari-bootstrap/ambari-bootstrap.sh

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then

    ## bug workaround:
    sed -i.bak "s/\(^    total_sinks_count = \)0$/\11/" /var/lib/ambari-server/resources/stacks/HDP/2.0.6/services/stack_advisor.py
    bash -c "nohup ambari-server restart" || true

    sleep 60

    ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari_change_pass admin admin ${ambari_pass}
    sleep 1

    cd ~/ambari-bootstrap/deploy

        ## various configuration changes for demo environments, and fixes to defaults
cat << EOF > configuration-custom.json
{
  "configurations" : {
    "core-site": {
        "fs.trash.interval": "4320"
    },
    "hdfs-site": {
      "dfs.namenode.safemode.threshold-pct": "0.99"
    },
    "hive-site": {
        "hive.server2.enable.doAs" : "true",
        "hive.server2.transport.mode": "http",
        "hive.exec.compress.output": "true",
        "hive.merge.mapfiles": "true",
        "hive.server2.tez.initialize.default.sessions": "true"
    },
    "mapred-site": {
        "mapreduce.job.reduce.slowstart.completedmaps": "0.7",
        "mapreduce.map.output.compress": "true",
        "mapreduce.output.fileoutputformat.compress": "true"
    },
    "yarn-site": {
        "yarn.acl.enable" : "true"
    },
    "ams-site": {
      "timeline.metrics.cache.size": "100"
    }
  }
}
EOF

    ./deploy-recommended-cluster.bash

    if [ "${deploy}" = "true" ]; then

        cd ~
        sleep 5
        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari_configs
        ambari_wait_request_complete 1
        cd ~
        sleep 10

        usermod -a -G users ${USER}
        usermod -a -G users admin
        echo "${ambari_pass}" | passwd admin --stdin
        sudo -u hdfs bash -c "
            hadoop fs -mkdir /user/admin;
            hadoop fs -chown admin /user/admin;
            hdfs dfsadmin -refreshUserToGroupsMappings"

        UID_MIN=$(awk '$1=="UID_MIN" {print $2}' /etc/login.defs)
        users="$(getent passwd|awk -v UID_MIN="${UID_MIN}" -F: '$3>=UID_MIN{print $1}')"
        for user in ${users}; do usermod -a -G users ${user}; done
        for user in ${users}; do usermod -a -G hadoop-users ${user}; done
        ~/ambari-bootstrap/extras/onboarding.sh
    fi
fi

