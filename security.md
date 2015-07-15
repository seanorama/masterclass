# Hadoop Security Masterclass

Notes and rough agenda

## Lab environments

Each user environment has 2 servers:

1. HDP:
	- `p-labNN-hdp`:  CentOS with Ambari 2.1 & HDP 2.3
	- OS authenticated with FreeIPA (via SSSD)
2. FreeIPA:
	- `p-labNN-ipa`: CentOS with FreeIPA (Kerberos/LDAP)

## Your HDP Cluster & system familiarity

#### Ambari: Web UI for management & use of HDP

* Ambari: p-labNN-hdp:8080
	* Credentials: admin/admin
* Knox:   p-labNN-hdp:8443
* Ranger: :6800

#### SSH: Remote shell

* Credentials:
	* user: student
	* key: provided separately
* Clients:
	* OSX & Linux: ssh student@
	* Windows: putty, openssh, ...
	* Web: http://hostname:4200 with password provided separately

#### Linux

* Get your internal hostname: `hostname -f`
* Get your public ip: `curl icanhazip.com`
* Run as root: `sudo ls /usr/hdp/current`
* Become another user: `sudo su - hdfs`

#### Hadoop

* Hadoop Commands:
	* make a directory: `hadoop fs -mkdir -p /dir/in/hadoop`
	* Put local file(s) into HDFS: `hadoop fs -put file1.csv file2.csv /dir/in/hadoop/`
	* Connect to Hive with beeline:

	```
beeline -n admin -u jdbc:hive2://localhost:10000/default`
> !connect jdbc:hive2://localhost:10000/default
	```
	

## Introduction Lab 01: Linux, Ambari & Hadoop

1. Open and login to Ambari
1. Restart services if required
1. SSH to your HDP server
1. Note the internal hostname of the server
1. Make the HDFS directory /tmp/lab01
1. Upload `hadoop-sample-data/trucks.csv` into /tmp/lab01