# Instructor notes
========================================

1. Get the repo and switch to the 'generic' directory

    ```
git clone https://github.com/seanorama/masterclass
cd masterclass/amazon-linux
    ```

2. Set these variables, updating the values as appropriate:

   ```sh
export AWS_DEFAULT_REGION=us-west-2 ## region to deploy in
export lab_prefix=${USER}         ## template for naming the cloudformation stacks
export lab_first=100                 ## number to start at in naming
export lab_count=1                   ## number of clusters to create

export cfn_parameters='
[
  {"ParameterKey":"KeyName","ParameterValue":"secloud"},
  {"ParameterKey":"SubnetId","ParameterValue":"subnet-76f4222f"},
  {"ParameterKey":"SecurityGroups","ParameterValue":"sg-1cb3f678"},
  {"ParameterKey":"HDPStack","ParameterValue":"2.5"},
  {"ParameterKey":"AmbariServices","ParameterValue":"HDFS MAPREDUCE2 PIG HIVE YARN ZOOKEEPER SPARK AMBARI_METRICS SQOOP TEZ FALCON KAFKA STORM OOZIE SLIDER"},
  {"ParameterKey":"AdditionalInstanceCount","ParameterValue":"3"},
  {"ParameterKey":"PostCommand","ParameterValue":"curl -sSL https://raw.githubusercontent.com/seanorama/masterclass/master/amazon-linux-llap/setup.sh | bash"},
  {"ParameterKey":"InstanceType","ParameterValue":"m4.2xlarge"},
  {"ParameterKey":"BootDiskSize","ParameterValue":"100"}
]
'
   ```

3. You can then execute ../bin/clusters-create.sh and the other cluster scripts as explained in ../README.md

## REMEMBER to terminate the clusters immediately after the class is over, or be prepared to pay $$$!

Further, you should verify deletion of the CloudFormations & EC2 instances from the AWS Console.

## Issues: See ../README.md

## Advanced usage

1. Only deploy the infrastructure by setting PostCommand to /bin/true
