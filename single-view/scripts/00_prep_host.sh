#!/usr/bin/env bash
set -o xtrace

cd /root
export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}

yum makecache
yum -y -q install epel-release
yum -y -q install autoconf python-crypto python-devel unzip gcc-c++ git python-argparse

git clone -b develop https://github.com/seanorama/ambari-bootstrap
~/ambari-bootstrap/extras/deploy/prep-hosts.sh

git clone https://github.com/seanorama/masterclass

#(
#cd /tmp
#wget http://hortonworks-masterclass.s3.amazonaws.com/single-view/data.zip
#unzip data.zip
#)

#yum -y -q install postgresql-server
#echo "host all all 127.0.0.1/32 md5" >> /var/lib/pgsql/data/pg_hba.conf

#service postgresql start
#chkconfig postgresql on
#sleep 5

#git clone https://github.com/abajwa-hw/single-view-demo
#sudo -i -u postgres psql -c "create database contoso;"
#sudo -i -u postgres psql -c "CREATE USER zeppelin WITH PASSWORD 'zeppelin';"
#sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE contoso to zeppelin;"
#sudo -i -u postgres psql -c "\du"
#export PGPASSWORD=zeppelin
#psql -U zeppelin -d contoso -h localhost -f ~/single-view-demo/contoso-psql.sql
#psql -U zeppelin -d contoso -h localhost -c "\dt"

#echo "zeppelin  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

