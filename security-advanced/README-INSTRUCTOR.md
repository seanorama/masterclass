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
export lab_prefix=sme-security      ## template for naming the cloudformation stacks
export lab_first=1                  ## number to start at in naming
export lab_count=1                  ## number of clusters to create
   ```

2. Set parameters for deploying into existing AWS VPC, Subnet & SecurityGroups

   ```sh
## Update with your subnet, securitygroups and the number of instances you want
export cfn_parameters='
ParameterKey=AdditionalInstanceCount,ParameterValue=2
ParameterKey=SubnetId,ParameterValue=subnet-76f4222f
ParameterKey=SecurityGroups,ParameterValue="sg-1c565979,sg-1cb3f678"
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
