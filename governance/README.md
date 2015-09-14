# Notes for our Hadoop Masterclasses

These notes are meant to accompany our Hadoop Governance Masterclass which covers:
- Apache Falcon for data lifecycle
- Apache Atlas for metadata
- Apache Ranger for policy enforcement and access audits

## Requirements

Tested with:

    - Ambari 2.1.1
    - HDP 2.3.0
    - OpenJDK 8

More details on the deployment process at the end of this document.

Many manual steps are automated using scripts from my [Ambari Bootstrap scripts](https://seanorama/ambari-bootstrap).
- Clone them to your server with: `cd ~; git clone https://seanorama/ambari-bootstrap`

## References

- Falcon CLI: http://falcon.apache.org/FalconCLI.html
    - Useful commands:

        ```
falcon entity -list -type cluster
falcon entity -list -type feed
falcon entity -list -type process
        ```

- [Falcon Data Pipeline documentation](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.0/bk_data_governance/content/ch_config_using_data_pipelines.html)

- Atlas
- Ranger



## Labs

### Lab: Configuration

- Falcon:
    - Give 'falcon' & 'oozie' users [Hadoop "proxyuser" rights](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/Superusers.html)
        - `proxyusers="falcon oozie" ~/ambari-bootstrap/extras/configs/proxyusers.sh`
    - Give 'falcon' user [Oozie "proxyuser" rights](https://oozie.apache.org/docs/4.2.0/AG_Install.html#User_ProxyUser_Configuration)
        - `proxyusers="falcon" ~/ambari-bootstrap/extras/oozie/proxyusers.sh`
- Atlas:
    - [Enable Hive Bridge](https://github.com/seanorama/ambari-bootstrap/blob/master/extras/atlas/atlas-hive-enable.sh)
- Ranger:
    - Install, Enable HDFS & Hive plugins, Install Solr & Solr dashboard

### Lab: HCatalog

1. Create table in Hive, and thus HCatalog
    - Open the Ambari View for Hive
    - Execute this:

    ```
CREATE TABLE `sample_07` (
`code` string ,
`description` string ,
`total_emp` int ,
`salary` int )
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TextFile;

LOAD DATA LOCAL INPATH '/opt/hadoop/samples/sample_07.csv' INTO TABLE sample_07;
    ```


1. Execute Pig Script
    - Open the Ambari View for Pig
    - Create a new script (with any name you like)
    - Add this argument (at the bottom): `-useHcatalog`
    - Provide this for the script:

    ```
-- Load table 'sample_07'
sample_07 = LOAD 'sample_07' USING org.apache.hive.hcatalog.pig.HCatLoader();
-- Compute the average salary of the table
salaries = GROUP sample_07 ALL;
out = FOREACH salaries GENERATE AVG(sample_07.salary);
DUMP out;
    ```

    - Execute the script

### Lab: Falcon HDFS mirroring

1. Setup directories:

```
hadoop fs -ls -R /apps/falcon/

mycluster=$(hostname -s)
clusterName=${mycluster} ~/ambari-bootstrap/extras/falcon/create-cluster-dirs.sh
clusterName=mirrorCluster ~/ambari-bootstrap/extras/falcon/create-cluster-dirs.sh

hadoop fs -ls -R /apps/falcon/
```

1. Create cluster entity for your cluster:
    - From command-line:

      ```
## list clusters
falcon entity -list -type cluster

## create cluster template
mycluster="$(hostname -s)"
myhost="$(hostname -f)"
sed -e "s/myCluster/${mycluster}/g" -e "s/myHost/${myhost}/g" ~/ambari-bootstrap/extras/falcon/myCluster.xml > "/tmp/${mycluster}.xml"

cat /tmp/${mycluster}.xml

## create cluster entity
sudo sudo -u admin falcon entity -submit -type cluster -file "/tmp/${mycluster}.xml"

## see cluster details
falcon entity -definition -type cluster -name ${mycluster}
      ```

1. Create cluster entity for **mirrorCluster**:
    - From Falcon UI:
        - Fields:
            - Name: mirrorCluster
            - Interfaces:
                - [ ] replace sandbox.hortonworks.com with the hostname of your mirror. For this example, I've updated /etc/hosts with a host named `mirror`:
                - [ ] add 'registry' interface:
                    - Endpoint: Change host to 'mirror'
                    - Version: 0.11.0
        - Screenshot ![Falcon UI](http://i.imgur.com/ZYb7hWl.png)
        - Alternatively from command-line:

    ```
mycluster="mirrorCluster"
myhost="mirror"
sed -e "s/myCluster/${mycluster}/g" -e "s/myHost/${myhost}/g" ~/ambari-bootstrap/extras/falcon/myCluster.xml > /tmp/${mycluster}.xml

sudo sudo -u admin falcon entity -submit -type cluster -file "/tmp/${mycluster}.xml"

falcon entity -list -type cluster
    ```

1. On source cluster, create a folder to replicate and put file(s) into it.
    - Ambari Files View makes this easy
    - For the example I create and put files in '/user/admin/mirror'

1. Create mirror entity
    - Choose Your Cluster as the source
    - Choose mirrorCluster as the target
    - Set the path source you made in the step above
    - Set the path target to wherever you want (e.g. /user/admin/mirrorTarget )
    - Set the start/end time to cover all of today
    - Save

1. Schedule mirror entity
    - Go back to Falcon UI
    - Search for *
    - Tick the box next to your mirror job
    - Click 'Schedule'
    - Click on the mirror to see the planned schedule

1. Inspect the mirror from the command-line:

    ```
falcon entity -list -type process

falcon entity -definition -type process -name myMirror

falcon instance -type process -name myMirror -list
    ```

1. Wait ~5 minutes, then check that replication has occured to the other cluster.

1. Add or alter files and then wait ~5 minutes to see the mirrored.


________________________________________

### Lab: Falcon Data Pipeline

- Prep the environment

```
sudo su - hdfs -c "hadoop fs -mkdir -p /shared/falcon/demo/primary/processed/enron; hadoop fs -chmod -R 777 /shared"
mkdir /tmp/falcon-churn; cd /tmp/falcon-churn
curl -sSL -O http://hortonassets.s3.amazonaws.com/tutorial/falcon/falcon.zip
unzip falcon.zip
sudo sudo -u admin hadoop fs -copyFromLocal demo /shared/falcon/
sudo sudo -u hdfs hadoop fs -chown -R admin:hadoop /shared/falcon
sudo sudo -u hdfs hadoop fs -chmod -R g+w /shared/falcon
```

Create Feeds & Processes from the Falcon UI using the XML below.

For each one, from the form:

  - Update the name to be unique (adding your cluster number to it)
  - Update the validity time start to this morning and end to tomorrow
  - Update the source cluster to be your cluster
  - Set the appropriate feeds
  - Then schedule before adding the next

Entities:

- https://raw.githubusercontent.com/seanorama/masterclass/master/governance/labs/falconChurnDemo/rawEmailFeed.xml
- https://raw.githubusercontent.com/seanorama/masterclass/master/governance/labs/falconChurnDemo/cleansedEmailFeed.xml
- https://raw.githubusercontent.com/seanorama/masterclass/master/governance/labs/falconChurnDemo/emailIngestProcess.xml
- https://raw.githubusercontent.com/seanorama/masterclass/master/governance/labs/falconChurnDemo/cleanseEmailProcess.xml


________________________________________


### Lab: Introduction to Atlas

- Atlas UI: Ambari -> Quick Links -> Atlas UI

- Let's load some types:

  ```
sudo /usr/hdp/current/atlas-server/bin/quick_start.py
  ```


- API:

  ```
## Verify if the server is up and running
  http http://localhost:21000/api/atlas/admin/version

## List the types in the repository
  http http://localhost:21000/api/atlas/types

## List the instances for a given type
  http "http://localhost:21000/api/atlas/entities?type=hive_table"
  http http://localhost:21000/api/atlas/entities/list/hive_db

## Search for entities (instances) in the repository
  http "http://localhost:21000/api/atlas/discovery/search/dsl?query=from hive_table"
```

### Lab: Atlas CLI (unofficial)

```
## Help
atlas-client --help

## Create a New DataSet Type

atlas-client --c=createDataSetType --type=Tims_Fict_Table

## Create new Traits and a Subtrait

atlas-client -c=createtrait --traitnames=SuperPM

atlas-client -c=createtrait --traittype=PM --parenttrait=SuperPM

## Create the entity with the Subtrait

atlas-client --c=createDataSetEntity --type=Tims_Fict_Table --name=Andrew_Demo --traitnames=PM

## Create a Data Set Search

atlas-client --c=search --type=Table --name=MYSQL_DRIVERS55

## Create a lineage

atlas-client --c=createProcessEntity --inptype=Tims_Fict_Table --outtype=Table --inpvalue=Andrew_Demo --outvalue=MYSQL_DRIVERS99 --traitnames=SuperPM --type=Jamies_Lineage --name=Lineage12
```

### Lab: Atlas Trucking data

1. Load tables from ERP (using Sqoop)

```
sqoop import --connect jdbc:mysql://localhost/test --username trucker1 --password trucker --table DRIVERS -m 1 --target-dir demo$1 --hive-import --hive-table DRIVERS$1
sqoop import --connect jdbc:mysql://localhost/test --username trucker1 --password trucker --table TIMESHEET -m 1 --target-dir demo$1 --hive-import --hive-table TIMESHEET$1
```

2. Manual loading of metadata

```
cd /opt/atlas-client
atlas-client --c=importmysql --mysqlhost=localhost --password=trucker \
    --username=trucker1 --db=test -createHiveTables -genLineage \
    --ambariClusterName=$(hostname -s) --suppress

```

3.  Inspect tables in Hive:

```
select * from drivers;
select * from timesheet;
```

4. In Atlas UI:

```
Table where name=”DRIVERS”
```

5. Determine bad drivers from Hive View:

```
create table bad_drivers AS select d.driver_name  , count(d.driver_name)  from DRIVERS d, TIMESHEET t where d.driver_id = t.driver_id and  t.hours_logged > 60 group by d.driver_name;
```

6. Loading business metadata

Inspect it:

```
cat /opt/atlas-client/resources/SensitivityHierarchy.json
```

```
cd /opt/atlas-client
sed -i.bak "s/Sandbox/$(hostname -s)/" resources/SensitivityHierarchy.json
atlas-client --c=loadtraithierarchy --jsonfilepath=./resources/SensitivityHierarchy.json
```
________________________________________

### Data Pipeline

#### Prepare the environment & load files to HDFS

```
sudo mkdir /app; chown student:users /app; chmod 777 /app; cd /app
git clone https://github.com/seanorama/hadoop-data-pipeline/
cd hadoop-data-pipeline/scripts/
sudo ./setupAppOnHDFS.sh
```

#### Update feed and inspect:

```
sudo ./changeValidityForFeed.sh
cat ../falcon/feeds/inputFeed.xml
```

#### Update process and inspect:

```
sudo ./changeValidityForProcess.sh
cat ../falcon/process/processData.xml
```

#### Inspect Workflow

```
cat ../falcon/workflow/workflow.xml
```

#### Submit Entities

```
sudo ./submitEntities.sh
```

#### Open Falcon to view Entities

#### Schedule Entities from Command Line or from UI

```
sudo ./scheduleEntities.sh
```

#### Land data in Flume

```
cp -a /app/hadoop-data-pipeline/input_data/SV-sample-1.xml /tmp/data_pipeline_demo/input/
```

#### Wait

#### Debug

```
hadoop fs -ls -R /user/admin/data_pipeline_demo/data
```
________________________________________

## Deployment notes

### Deploy your host(s)

Requirements:

  - CentOS 7 (Should also work with CentOS & RedHat 6)
  - Single node without HDP deployed.
    - Look at the setup script if you want to configure on an existing HDP cluster.
  - full sudoers access

### Configure cluster for the masterclass

This should be done on 1 node clusters

- For a single cluster clone this repository and then execute [./setup.sh](./setup.sh)

- If using PDSH or similar commands, you can use curl to execute the script as seen below with PDSH.
    - (make sure to set the hosts_all variable to your host list, or update the command to use a file)

    ```
read -r -d '' command <<EOF
curl -sSL https://raw.githubusercontent.com/seanorama/masterclass/master/governance/setup.sh | bash
EOF
pdsh -w ${hosts_all} "${command}"
    ```

### Configure mirror server

Deploy a server just like the lab systems but add:

- Install Ranger from Ambari
- Setup Ranger Plugins & Solr Dashboard

  ```
~/ambari-bootstrap/extras/ranger/ranger-plugin-hdfs.sh
~/ambari-bootstrap/extras/ranger/ranger-plugin-hbase.sh
~/ambari-bootstrap/extras/ranger/ranger-plugin-hive.sh
~/ambari-bootstrap/extras/ranger/ranger-plugin-yarn.sh
~/ambari-bootstrap/extras/ranger/solr-dashboard.sh publicip
~/ambari-bootstrap/extras/ranger/ranger-solr-audit.sh
  ```

- Add mirrorCluster to the host

  ```
mycluster="mirrorCluster"
myhost="$(hostname -f)"

clusterName=${mycluster} ~/ambari-bootstrap/extras/falcon/create-cluster-dirs.sh
sed -e "s/myCluster/${mycluster}/g" -e "s/myHost/${myhost}/g" ~/ambari-bootstrap/extras/falcon/myCluster.xml > /tmp/${mycluster}.xml
sudo sudo -u admin falcon entity -submit -type cluster -file "/tmp/${mycluster}.xml"
sudo su - hdfs -c "hadoop fs -mkdir -p /shared/falcon/demo/bcp/processed/enron; hadoop fs -chown -R admin:hadoop /shared; hadoop fs -chmod -R 777 /shared"
  ```

- Cleanup Oozie on mirrorHost

```
oozie jobs -oozie http://$(hostname -f):11000/oozie|grep -E "(Feed|Process)" | awk '{print $1}' \
    | xargs -i{} sudo sudo -u oozie oozie job  -oozie http://$(hostname -f):11000/oozie -kill {}
oozie jobs -oozie http://$(hostname -f):11000/oozie  -jobtype coordinator |grep -E "(Feed|Process|PROCESS)" | awk '{print $1}' \
    | xargs -i{} sudo sudo -u oozie oozie job  -oozie http://$(hostname -f):11000/oozie -kill {}
oozie jobs -oozie http://$(hostname -f):11000/oozie  -jobtype bundle |grep -E "(Feed|Process|PROCESS)" | awk '{print $1}' \
    | xargs -i{} sudo sudo -u oozie oozie job  -oozie http://$(hostname -f):11000/oozie -kill {}
```
