#!/usr/bin/env bash
set -o xtrace

el_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1)
case ${el_version} in
  "6")
    true
  ;;
  "7")
    rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  ;;
esac

yum makecache
yum -y -q install git epel-release ntpd

cd
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash
~/ambari-bootstrap/ambari-bootstrap.sh
sleep 10

## Ambari Server specific tasks
if [ "${install_ambari_server}}" = "true" ]; then
    yum -y -q install jq python-argparse python-configobj
    source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari-change-pass admin admin ${ref_ambari_pass}

    if [ "${ref_deploy_cluster}" = "True" ]; then
        export ambari_pass="${ref_ambari_pass}"
        export ambari_password="${ambari_pass}"
        export cluster_name=${stack}
        export host_count=$((ref_additional_instance_count + 1))
        cd ~/ambari-bootstrap/deploy
        ./deploy-recommended-cluster.bash
        cd ~
        sleep 5

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari-configs
        ambari_wait_request_complete 1
    fi
fi

exit 0

