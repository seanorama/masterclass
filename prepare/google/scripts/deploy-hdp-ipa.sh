#!/usr/bin/env bash

curl -sSL -O https://github.com/seanorama/masterclass/blob/master/prepare/google/scripts/ipautil.patch
sudo patch -b /usr/lib/python2.6/site-packages/ipapython/ipautil.py < ipautil.patch
#sudo ipa-client-install --domain=hortonworks.local --server="$(hostname -s|sed 's/-hdp/-ipa/').$(hostname -d)" -p admin@HORTONWORKS.LOCAL --mkhomedir --fixed-primary --enable-dns-updates --ssh-trust-dns -N -W
sudo ipa-client-install --domain=hortonworks.local --server="$(hostname -s|sed 's/-hdp/-ipa/').$(hostname -d)" -p admin@HORTONWORKS.LOCAL --mkhomedir --fixed-primary -N -W --hostname=$(hostname -f)

