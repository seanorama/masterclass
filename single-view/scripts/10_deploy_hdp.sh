#!/usr/bin/env bash

cd ~

test -f ~/masterclass.env && source ~/masterclass.env
export ambari_pass="${ambari_pass:-BadPass#1}"
export cluster_name="${cluster_name:-mycluster}"

## Install Python in virtualenv
VERSION=15.0.1
curl -sSL https://pypi.python.org/packages/source/v/virtualenv/virtualenv-$VERSION.tar.gz   | tar xz
$(which python) virtualenv-$VERSION/virtualenv.py ~/python
rm -rf virtualenv-$VERSION; unset VERSION
set +u ; source ~/python/bin/activate; set -u
pip install ansible boto six ruamel.yaml

## ansible-hadoop
git clone -b develop https://github.com/seanorama/ansible-hadoop
cd ansible-hadoop

printf "[master-nodes]\nlocalhost ansible_ssh_host=localhost\n" \
  > inventory/static

sed -i.bak \
  -e "s/^\(cluster_name: \).*/\1'${cluster_name}'/" \
  -e "s/^\(admin_password: \).*/\1'${ambari_pass}'/" \
  -e "s/^\(update_etc_hosts: \).*/\1false/" \
  -e "s/^\(java_type: \).*/\1open/" \
  -e "s/^\(tech_preview: \).*/\1true/" \
  -e "s/^\(install_nifi: \).*/\1true/" \
  -e "s/^\(install_solr: \).*/\1true/" \
  -e "s/^\(install_ams: \).*/\1true/" \
  -e "s/^\(install_zeppelin: \).*/\1true/" \
  -e "s/^\(install_falcon: \).*/\1false/" \
  -e "s/^\(install_flume: \).*/\1false/" \
  -e "s/^\(install_oozie: \).*/\1false/" \
  -e "s/^\(install_kafka: \).*/\1false/" \
  -e "s/^\(install_slider: \).*/\1false/" \
  -e "s/^\(install_storm: \).*/\1false/" \
  -e "s/^\(deploy_hadoop: \).*/\1true/" \
  playbooks/group_vars/all

ansible-playbook -i inventory/static -c local playbooks/bootstrap.yml
ansible-playbook -i inventory/static -c local playbooks/hortonworks.yml

sleep 60

## Wait until cluster is built
echo "export ambari_pass=BadPass#1" >> ~/.ambari.conf
chmod 600 ~/.ambari.conf
source ~/ambari-bootstrap/extras/ambari_functions.sh
ambari_configs
ambari_wait_request_complete 1

