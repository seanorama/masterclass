#!/usr/bin/env bash

export lab_prefix=${lab_prefix:-mc-test}
lab_first=${lab_first:-1}
lab_count=${lab_count:-1}

clusters=$(seq -w ${lab_first} $((lab_first+lab_count-1)))
clusters=$(for cluster in ${clusters}; do echo ${lab_prefix}${cluster}; done)

echo "########################################"
echo "## Status of the cluster's CloudFormation Stacks:"
for cluster in ${clusters}
do
  aws cloudformation describe-stacks \
      --query 'Stacks[*].[StackName, StackStatus]' \
      --stack-name ${cluster} \
      --output text
done
echo "########################################"

