#!/usr/bin/env bash

# This script will grow the root file system on redhat/centos 6&7
#
# Tested on Google Compute VMs
#

sudo yum -y install epel-release
sudo yum makecache
sudo yum -y install perl cloud-init cloud-initramfs-tools dracut-modules-growroot cloud-utils-growpart
rpm -qa kernel | perl -pe 's/^kernel-//' | xargs -I {} sudo dracut -f /boot/initramfs-{}.img {}
sleep 5
sudo reboot
