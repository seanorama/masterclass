#!/usr/bin/env bash

sudo yum -y install screen

ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
echo "${ip} $(hostname -s).cloudapp.net $(hostname -s)" | sudo tee -a /etc/hosts

el_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1)
case ${el_version} in
  "6")
    echo "HOSTNAME=$(hostname -s).cloudapp.net" | sudo tee -a /etc/sysconfig/network
    sudo hostname $(hostname -s).cloudapp.net
    screen -dmS restart-networking bash
    screen -S restart-networking -X stuff "sleep 2; sudo service network restart; exit\n"
  ;;
  "7")
    sudo hostnamectl set-hostname $(hostname -s).cloudapp.net
    sudo systemctl restart systemd-hostnamed
  ;;
esac

exit
