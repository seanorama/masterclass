# Instructor notes
========================================

## Requirements
----------------------------------------

- AWS CLI configured
- Hortonworkers: Access to AWS SE account (see the wiki)

----------------------------------------

## Infrastructure preparation
----------------------------------------


----------------------------------------

## AWS specific notes
----------------------------------------

The following uses AWS CloudFormation to deploy however many clusters (`lab_count`) you want.

1. Prepare your environment

   ```sh
export AWS_DEFAULT_REGION=us-west-2 ## region to deploy in
export lab_prefix=sec      ## template for naming the cloudformation stacks
export lab_first=1                  ## number to start at in naming
export lab_count=1                  ## number of clusters to create
   ```

2. Set parameters for deploying into existing AWS VPC, Subnet & SecurityGroups

   ```sh
## Update with your keypair name, subnet, securitygroups and the number of instances you want
export cfn_parameters='
[
  {"ParameterKey":"KeyName","ParameterValue":"training-keypair"},
  {"ParameterKey":"AmbariServices","ParameterValue":"HDFS MAPREDUCE2 PIG YARN HIVE ZOOKEEPER"},
  {"ParameterKey":"AdditionalInstanceCount","ParameterValue":"2"},
  {"ParameterKey":"SubnetId","ParameterValue":"subnet-02edac67"},
  {"ParameterKey":"SecurityGroups","ParameterValue":"sg-a02d17c4"}]
'
   ```

3. Deploy

   ```
../bin/clusters-create.sh
   ```

   ```
../bin/clusters-report.sh
   ```

   ```
../bin/clusters-terminate.sh
   ```

----------------------------------------
