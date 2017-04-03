#!/usr/bin/env bash
beeline -n hive -u "jdbc:hive2://localhost:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -f create-secgovdemo-hortoniabank-tables.ddl

