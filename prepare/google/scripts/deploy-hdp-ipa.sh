#!/usr/bin/env bash

curl -sSL -O https://gist.githubusercontent.com/seanorama/fca566e558b6a459d362/raw/ae2c9ba08c771d91c41df2c97dda0eccfe137fc0/ipautil.el6.patch
sudo patch -b /usr/lib/python2.6/site-packages/ipapython/ipautil.py < ipautil.el6.patch
#sudo ipa-client-install --domain=hortonworks.local --server="$(hostname -s|sed 's/-hdp/-ipa/').$(hostname -d)" -p admin@HORTONWORKS.LOCAL --mkhomedir --fixed-primary --enable-dns-updates --ssh-trust-dns -N -W
#sudo ipa-client-install --domain=hortonworks.local --server="$(hostname -s|sed 's/-hdp/-ipa/').$(hostname -d)" -p admin@HORTONWORKS.LOCAL --mkhomedir --fixed-primary -N -W --hostname=$(hostname -f)

