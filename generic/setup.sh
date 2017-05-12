#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
export TERM=xterm
: ${ambari_pass:="BadPass#1"}
ambari_password="${ambari_pass}"
: ${cluster_name:="mycluster"}
: ${ambari_services:="HDFS MAPREDUCE2 PIG YARN HIVE ZOOKEEPER AMBARI_METRICS SLIDER AMBARI_INFRA TEZ"}
: ${install_ambari_server:=true}
: ${ambari_stack_version:=2.5}
: ${host_count:=skip}
: ${recommendation_strategy:="ALWAYS_APPLY_DONT_OVERRIDE_CUSTOM_VALUES"}

: ${install_nifi:=false}
nifi_version=1.1.2

export install_ambari_server ambari_pass host_count ambari_services
export ambari_password cluster_name recommendation_strategy

cd

yum makecache
yum -y -q install git epel-release ntpd screen mysql-connector-java jq python-argparse python-configobj ack

curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash

~/ambari-bootstrap/extras/deploy/prep-hosts.sh

~/ambari-bootstrap/ambari-bootstrap.sh

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then
    bash -c "nohup ambari-server restart" || true

    sleep 60

    ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari_change_pass admin admin ${ambari_pass}
    sleep 1

    if [ "${deploy}" = "true" ]; then

        cd ~/ambari-bootstrap/deploy

        ## various configuration changes for demo environments, and fixes to defaults
cat << EOF > configuration-custom.json
{
  "configurations" : {
    "core-site": {
        "hadoop.proxyuser.root.users" : "admin",
        "fs.trash.interval": "4320"
    },
    "hdfs-site": {
      "dfs.namenode.safemode.threshold-pct": "0.99"
    },
    "hive-site": {
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
    }
  }
}
EOF

        ./deploy-recommended-cluster.bash

        if [ "${install_nifi}" = "true" ]; then
            cd /opt
            curl -ssLO http://mirrors.ukfast.co.uk/sites/ftp.apache.org/nifi/${nifi_version}/nifi-${nifi_version}-bin.tar.gz
            tar -xzvf nifi-${nifi_version}-bin.tar.gz
            sed -i 's/^\(nifi.web.http.port=\).*/\19090/' nifi-${nifi_version}/conf/nifi.properties
            /opt/nifi-${nifi_version}/bin/nifi.sh start
        fi

        cd ~
        sleep 5
        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari_configs
        ambari_wait_request_complete 1
        cd ~
        sleep 10

        usermod -a -G users ${USER}
        echo "${ambari_pass}" | passwd admin --stdin
        sudo sudo -u hdfs bash -c "
            hadoop fs -mkdir /user/admin;
            hadoop fs -chown admin /user/admin;
            hdfs dfsadmin -refreshUserToGroupsMappings"
    fi
fi

