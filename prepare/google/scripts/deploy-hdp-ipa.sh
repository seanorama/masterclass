#!/usr/bin/env bash

pass=hortonworks

sudo yum makecache
sudo yum -y install ipa-client openldap-clients patch
sudo service ntpd restart

curl -sSL -O https://raw.githubusercontent.com/seanorama/masterclass/master/prepare/google/scripts/ipautil.patch
sudo patch -f -b /usr/lib/python2.6/site-packages/ipapython/ipautil.py < ipautil.patch

echo ${pass} | sudo ipa-client-install -U --domain=hortonworks.com \
  --server="$(hostname -s|sed 's/-hdp/-ipa/').$(hostname -d)" \
  -p admin@HORTONWORKS.COM --mkhomedir --fixed-primary -N -W \
  --hostname=$(hostname -f)

echo ${pass} | kinit admin
echo ${pass} | sudo kinit admin
