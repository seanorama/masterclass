#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}
#export ambari_server_custom_script="sed -i 's/amazon2015/amazon2016/' /usr/lib/ambari-*/lib/ambari_commons/resources/os_family.json /var/lib/ambari-server/resources/stacks/HDP/*/services/*/metainfo.xml /var/lib/ambari-server/resources/common-services/*/*/metainfo.xml /var/lib/ambari-agent/cache/common-services/*/*/metainfo.xml /var/lib/ambari-agent/cache/stacks/HDP/*/services/*/metainfo.xml; ambari-server refresh-stack-hash; ambari-agent restart"
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
        ./deploy-recommended-cluster.bash
    fi
fi
