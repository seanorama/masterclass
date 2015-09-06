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


### Lab: Falcon HDFS mirroring

1. Setup directories:

```
hadoop fs -ls -R /apps/falcon/

clusterName=primaryCluster ~/ambari-bootstrap/extras/falcon/create-cluster-dirs.sh
clusterName=mirrorCluster ~/ambari-bootstrap/extras/falcon/create-cluster-dirs.sh

hadoop fs -ls -R /apps/falcon/
```

1. Create cluster entity for **primaryCluster**:
    - From command-line:

      ```
## list clusters
falcon entity -list -type cluster

## create cluster template
mycluster="primaryCluster"
myhost="$(hostname -f)"
sed -e "s/myCluster/${mycluster}/g" -e "s/myHost/${myhost}/g" ~/ambari-bootstrap/extras/falcon/myCluster.xml > "/tmp/${mycluster}.xml"

cat ~/ambari-bootstrap/extras/falcon/primaryCluster.xml

## create cluster entity
sudo sudo -u admin falcon entity -submit -type cluster -file "/tmp/${mycluster}.xml"

## see cluster details
falcon entity -definition -type cluster -name primaryCluster
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
    - Choose primaryCluster as the source
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

```
sudo su - hdfs -c "hadoop fs -mkdir /shared; hadoop fs -chmod 777 /shared"

mkdir /tmp/falcon-churn; cd /tmp/falcon-churn
curl -sSL -O http://hortonassets.s3.amazonaws.com/tutorial/falcon/falcon.zip
unzip falcon.zip
sudo sudo -u admin hadoop fs -mkdir -p /shared/falcon
sudo sudo -u admin hadoop fs -copyFromLocal demo /shared/falcon/
sudo sudo -u admin hadoop fs -chmod -R g+w /shared/falcon
sudo sudo -u hdfs hadoop fs -chgrp -R hadoop /shared/falcon
```



- Load the demo files and create entities from the command line

```
sudo mkdir /app; chown student:users /app; chmod 775 /app; cd /app
git clone https://github.com/seanorama/hadoop-data-pipeline/
cd hadoop-data-pipeline/scripts/
sudo ./setupAppOnHDFS.sh
sudo ./changeValidityForFeed.sh
sudo ./changeValidityForProcess.sh
sudo ./submitEntities.sh
```

- Go to Falcon UI & schedule the Demo Feed & Process

- View the status of the process

- But Flume hasn't loaded any data. So lets give Flume some data:

```
sudo cp /app/hadoop-data-pipeline/input_data/SV-sample-1.xml /root/data_pipeline_demo/input
```

sudo cp /app/hadoop-data-pipeline/input_data/SV-sample-2.xml /root/data_pipeline_demo/input

- Now we will wait for the next process run.






Now lets load our Feed & Process from the UI

1. Create Feed Entity from UI:
    - Open this URL in your browser and copy the contents: https://raw.githubusercontent.com/seanorama/hadoop-data-pipeline/master/falcon/feeds/inputFeed.xml
    - Open your Falcon UI
    - Create a new Feed Entity
        - Paste the XML contents from the URL above
        - Update the Timezone to GMT (on "2 properties" page)
        - Update the Cluster to your Cluster (on "4 properties" page)
        - Update the Validity start to this morning (08:00am) and end to a date in the future
        - Save

2. Create Process Entity from UI:
    - Repeat similar steps to above but with this XML: https://raw.githubusercontent.com/seanorama/hadoop-data-pipeline/master/falcon/process/processData.xml

3. Schedule the Entities: Feed then process

https://github.com/seanorama/hadoop-data-pipeline/blob/master/falcon/process/processData.xml

### Lab: 

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
  ```
