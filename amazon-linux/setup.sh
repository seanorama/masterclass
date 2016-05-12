#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
cd

export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}
export ambari_version=2.2.2.0

yum makecache
yum -y -q install git patch

## monkeypatching ambari-agent for Amazon Linux 2016.03
##                smartsense for Python=>2.7.9

yum -y -q install smartsense-hst
URL="https://gist.githubusercontent.com/seanorama/bbe936cff511d8e5b98f1c8b6c155f55/raw/5446e0747e0a6e99b49c881e23a70748aec97b19/security.py.diff"
curl -sSL "${URL}" | patch -b /usr/hdp/share/hst/hst-agent/lib/hst_agent/security.py

git clone -b feature/amazon-linux http://github.com/seanorama/ambari-bootstrap
cd ambari-bootstrap

# export install_ambari_server=true
./ambari-bootstrap.sh

URL="https://gist.githubusercontent.com/seanorama/fdd64d9648ad3d7897d5115e02f532bd/raw/00b11e7cb87c5d9e5662eb3634ce41f9889a5fcb/BUG-57329.diff"
curl -sSL -O "${URL}"
for a in agent server; do
    patch -b \
        /usr/lib/ambari-${a}/lib/ambari_commons/resources/os_family.json \
        BUG-57329.diff || true
done
rm BUG-57329.diff

bash -c "nohup ambari-agent restart" || true

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then
    bash -c "nohup ambari-server restart" || true

    sleep 60

    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari-change-pass admin admin ${ambari_pass}

    if [ "${deploy}" = "true" ]; then

        export ambari_password="${ambari_pass}"
        export cluster_name=${stack:-mycluster}
        export host_count=${host_count:-skip}
        export ambari_services="${ambari_services:-HDFS MAPREDUCE2 PIG HIVE YARN ZOOKEEPER SPARK AMBARI_METRICS SQOOP TEZ SMARTSENSE}"

        cd ~/ambari-bootstrap/deploy

cat << EOF > configuration-custom.json
{
  "configurations" : {
    "hst-server-conf": {
          "customer.account.name" : "Internal: AWS Marketplace",
          "customer.smartsense.id" : "A-99900000-C-00000001",
          "customer.notification.email" : "sroberts@hortonworks.com",
          "server.storage.dir" : "/var/lib/smartsense/hst-server/data",
          "server.tmp.dir" : "/var/lib/smartsense/hst-server/tmp"
    },
    "hst-agent-conf": {
          "agent.tmp_dir" : "/var/lib/smartsense/hst-agent/data/tmp"
    },
    "hdfs-site" : {
        "dfs.namenode.name.dir" : "/grid/00/hadoop/hdfs/nn,/grid/01/hadoop/hdfs/nn",
        "dfs.journalnode.edits.dir" : "/grid/00/hadoop/hdfs/jn,/grid/01/hadoop/hdfs/jn",
        "dfs.datanode.data.dir" : "/grid/00/hadoop/hdfs/dn,/grid/01/hadoop/hdfs/dn",
        "dfs.datanode.failed.volumes.tolerated" : "1"
    }
  }
}
EOF
        ./deploy-recommended-cluster.bash

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari-configs
        ambari_wait_request_complete 1

        cd ~
        sleep 10

        bash -c "nohup ambari-server agent" || true

    fi
fi

