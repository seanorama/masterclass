#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}
#export ambari_server_custom_script="sed -i 's/amazon2015/amazon2016/' /usr/lib/ambari-*/lib/ambari_commons/resources/os_family.json /var/lib/ambari-server/resources/stacks/HDP/*/services/*/metainfo.xml /var/lib/ambari-server/resources/common-services/*/*/metainfo.xml /var/lib/ambari-agent/cache/common-services/*/*/metainfo.xml /var/lib/ambari-agent/cache/stacks/HDP/*/services/*/metainfo.xml; ambari-server refresh-stack-hash; ambari-agent restart"
export ambari_server_custom_script="yum -y -q install smartsense-hst"
export ambari_version=2.2.2.0

cd

yum makecache
yum -y -q install git

git clone -b feature/amazon-linux http://github.com/seanorama/ambari-bootstrap
cd ambari-bootstrap

# export install_ambari_server=true
./ambari-bootstrap.sh

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then
    bash -c "nohup ambari-server start" || true

    sleep 60

    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari-change-pass admin admin ${ambari_pass}

    if [ "${deploy}" = "true" ]; then

        export ambari_password="${ambari_pass}"
        export cluster_name=${stack:-mycluster}
        export host_count=${host_count:-skip}
        export ambari_services="${ambari_services:-HDFS MAPREDUCE2 PIG HIVE YARN ZOOKEEPER}"

        cd ~/ambari-bootstrap/deploy

cat << EOF > configuration-custom.json
{
  "configurations" : {
    "hst-server-conf": {
          "customer.account.name" : "Internal AWS Marketplace sroberts",
          "customer.smartsense.id" : "A-00000000-C-00000000",
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
    fi
fi
