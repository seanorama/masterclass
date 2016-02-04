# Instructor notes
========================================

These instructions will create lab environments for:

  - a. HDP Cluster: 1 node with HDFS, YARN, HIVE, NIFI, SOLR, SPARK, ZEPPELIN
  - b. Nifi: 1 node with nifi

You should **open 2 separate shells** for deploying each environment. This is due to the management scripts depending on environment variables.

## Before you start

See ../README.md for instructions on using the cluster management scripts (step 3 in the processes below):

  - ../bin/cluster-create.sh
  - ../bin/cluster-report.sh
  - ../bin/cluster-terminate.sh

## Deploy clusters
Open 2 clean shell environments on a host where the AWS CLI has been configured.

### a) Deploy the HDP node

1. Get the repo and switch to the 'generic' directory

    ```
git clone https://github.com/seanorama/masterclass
cd masterclass/generic
    ```

2. Set these variables, updating the values as appropriate:

   ```sh
export AWS_DEFAULT_REGION=eu-west-1  ## region to deploy in
export lab_prefix=mc-hdf-hdp         ## template for naming the cloudformation stacks
export lab_first=100                 ## number to start at in naming
export lab_count=1                   ## number of clusters to create

export cfn_parameters='
[
  {"ParameterKey":"KeyName","ParameterValue":"secloud"},
  {"ParameterKey":"SubnetId","ParameterValue":"subnet-7e49641b"},
  {"ParameterKey":"SecurityGroups","ParameterValue":"sg-f915bc9d"},
  {"ParameterKey":"AmbariServices","ParameterValue":"HDFS MAPREDUCE2 PIG YARN HIVE ZOOKEEPER NIFI SOLR KAFKA"},
  {"ParameterKey":"InstanceType","ParameterValue":"m4.xlarge"},
  {"ParameterKey":"BootDiskSize","ParameterValue":"80"}
]
'
   ```

3. You can then execute ../bin/clusters-create.sh and the other cluster scripts as explained in ../README.md

### b) Deploy the NiFi node

In the 2nd shell:

1. Switch to the 'generic' directory

    ```
cd masterclass/generic
    ```

2. Set these variables, updating the values as appropriate:

    ```sh
export AWS_DEFAULT_REGION=eu-west-1  ## region to deploy in
export lab_prefix=mc-hdf-nifi        ## template for naming the cloudformation stacks
export lab_first=100                 ## number to start at in naming
export lab_count=1                   ## number of clusters to create

export cfn_parameters='
[
  {"ParameterKey":"KeyName","ParameterValue":"secloud"},
  {"ParameterKey":"SubnetId","ParameterValue":"subnet-7e49641b"},
  {"ParameterKey":"SecurityGroups","ParameterValue":"sg-f915bc9d"},
  {"ParameterKey":"AmbariServices","ParameterValue":"NIFI"},
  {"ParameterKey":"InstanceType","ParameterValue":"t2.medium"},
  {"ParameterKey":"BootDiskSize","ParameterValue":"80"}
]
'
   ```

3. You can then execute ../bin/clusters-create.sh and the other cluster scripts as explained in ../README.md

## REMEMBER to terminate the clusters immediately after the class is over, or be prepared to pay $$$!

Further, you should verify deletion of the CloudFormations & EC2 instances from the AWS Console.

## Issues: See ../README.md
