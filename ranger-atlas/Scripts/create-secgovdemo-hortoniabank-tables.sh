#!/usr/bin/env bash

#su - hadoopadmin
#-- Password BadPass#1

#kinit
#-- Password BadPass#1

#beeline -u "jdbc:hive2://smegovdemo2.field.hortonworks.com:10000/default;principal=hive/$(hostname -f)@HORTONWORKS.COM"
beeline -n hive -u "jdbc:hive2://localhost:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -f create-secgovedemo-hortoniabank-tables.ddl

