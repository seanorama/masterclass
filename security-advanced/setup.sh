#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
export TERM=xterm
: ${ambari_pass:="BadPass#1"}
ambari_password="${ambari_pass}"
: ${ambari_services:="HDFS MAPREDUCE2 PIG YARN HIVE ZOOKEEPER AMBARI_METRICS SLIDER AMBARI_INFRA LOGSEARCH TEZ"}
: ${install_ambari_server:=true}
: ${ambari_stack_version:=2.5}
cluster_name=${stack:-mycluster}

: ${install_ambari_server:=true}
: ${ambari_stack_version:=2.5}
: ${host_count:=skip}

: ${recommendation_strategy:="ALWAYS_APPLY_DONT_OVERRIDE_CUSTOM_VALUES"}

export install_ambari_server ambari_pass host_count ambari_services
export ambari_password cluster_name recommendation_strategy

cd

yum makecache
yum -y -q install git epel-release ntpd screen mysql-connector-java jq python-argparse python-configobj ack

########
########
## Install rackerlabs/recap to gather metrics
yum -y -q install git bc elinks net-tools sysstat iotop
git clone https://github.com/rackerlabs/recap.git
cd recap; make install; cd

opts="USESAR USESARR USESARQ USEPSTREE USENETSTATSUM USEDF USESLAB USEFDISK"
for opt in ${opts}
do
  sed -i "s/${opt}=no/${opt}=yes/" /etc/recap
done
unset opts

recap
echo '*/5 * * * * root /usr/sbin/recap' >> /etc/cron.d/recap
########
########

#ad_ip=172.30.0.78
#echo "${ad_ip} ad01.lab.hortonworks.net ad01" | sudo tee -a /etc/hosts

curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash

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
    "hive-interactive-env": {
        "enable_hive_interactive": "true",
        "llap_queue_capacity": "75"
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
    },
    "yarn-site": {
        "yarn.acl.enable" : "true"
    }
  }
}
EOF

        ./deploy-recommended-cluster.bash
        cd ~
        sleep 5

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari_configs
        ambari_wait_request_complete 1
    fi
fi

exit 0

