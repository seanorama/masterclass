#!/usr/bin/env bash

#export clusters="apple apricot banana blackberry blackcurrant blueberry coconut cherry clementine cranberry damson elderberry fig gooseberry grape guava huckleberry lemon lime lychee mango melon nectarine orange passionfruit peach pear persimmon plum prune pineapple pomegranate raspberry satsuma strawberry tangerine"
clusters=${clusters:-apple}

for fruitycluster in ${clusters}
do

  echo "####################################################"
  echo "This is the $fruitycluster cluster"
  echo "####################################################"
  echo "This will be operated by: <1st PERSON NAME HERE>"
  echo "                     and: <2nd PERSON NAME HERE>"
  echo "####################################################"
  echo ""
  echo "This is the $fruitycluster cluster Ambari Node"
  echo "public name:"
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PublicDnsName]' --filters Name=instance-state-name,Values=running Name=tag:aws:cloudformation:stack-name,Values=$fruitycluster Name=tag:aws:cloudformation:logical-id,Values=AmbariNode --output text
  echo ""
  echo "private name:"
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PrivateDnsName]' --filters Name=instance-state-name,Values=running Name=tag:aws:cloudformation:stack-name,Values=$fruitycluster Name=tag:aws:cloudformation:logical-id,Values=AmbariNode --output text
  echo ""
  echo "These are the $fruitycluster cluster Master Nodes"
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PrivateDnsName]' --filters Name=instance-state-name,Values=running Name=tag:aws:cloudformation:stack-name,Values=$fruitycluster Name=tag:aws:cloudformation:logical-id,Values=MasterNodes --output text
  echo ""
  echo "These are the $fruitycluster cluster Data Nodes"
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PrivateDnsName]' --filters Name=instance-state-name,Values=running Name=tag:aws:cloudformation:stack-name,Values=$fruitycluster Name=tag:aws:cloudformation:logical-id,Values=WorkerNodes --output text
  echo ""
done
