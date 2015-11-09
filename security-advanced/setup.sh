#!/usr/bin/env bash
set -o xtrace

export TERM=xterm

el_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1)
case ${el_version} in
  "6")
    true
  ;;
  "7")
    rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  ;;
esac

echo "172.31.0.175 ad01.lab.hortonworks.net ad01" >> /etc/hosts

yum makecache
yum -y -q install git epel-release ntpd

cd
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash
#export ambari_repo=http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos7/2.x/BUILDS/2.1.3.0-291/ambaribn.repo
export ambari_repo=http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos7/2.x/BUILDS/2.1.3.0-323/ambaribn.repo
~/ambari-bootstrap/ambari-bootstrap.sh
sleep 10

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then
    bash -c "nohup ambari-server start" || true
    yum -y -q install mysql-connector-java jq python-argparse python-configobj
    ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari-change-pass admin admin ${ambari_pass}

    if [ "${deploy}" = "true" ]; then
        export ambari_password="${ambari_pass}"
        export cluster_name=${stack}
        export host_count=${host_count:-skip}
        cd ~/ambari-bootstrap/deploy
        export export ambari_services="ACCUMULO AMBARI_METRICS FALCON FLUME HBASE HDFS HIVE KNOX MAHOUT MAPREDUCE2 OOZIE PIG SLIDER SPARK SQOOP STORM TEZ YARN ZOOKEEPER"
        ./deploy-recommended-cluster.bash
        cd ~
        sleep 5

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari-configs
        ambari_wait_request_complete 1
    fi
fi

exit 0

