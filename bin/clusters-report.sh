#!/usr/bin/env bash

export lab_prefix=${lab_prefix:-${USER}}
lab_first=${lab_first:-100}
lab_count=${lab_count:-1}

clusters=$(seq -w ${lab_first} $((lab_first+lab_count-1)))
clusters=$(for cluster in ${clusters}; do echo ${lab_prefix}${cluster}; done)

for cluster in ${clusters}
do
  echo "####################################################"
  echo "## $cluster is operated by: <Names Here>"
  for nodetype in AmbariNode AdditionalNodes; do
      printf "${nodetype}: "; aws ec2 describe-instances \
          --query \
            'Reservations[*].Instances[*].[PublicIpAddress]' \
          --filters Name=instance-state-name,Values=running \
            Name=tag:aws:cloudformation:stack-name,Values=$cluster \
            Name=tag:aws:cloudformation:logical-id,Values=${nodetype} --output text | xargs echo
  done
done

      #aws ec2 describe-instances \
          #--query \
            #'Reservations[*].Instances[*].[
                #Tags[?Key==`aws:cloudformation:logical-id`].Value[]
                #,PublicIpAddress]' \
          #--filters Name=instance-state-name,Values=running \
            #Name=tag:aws:cloudformation:stack-name,Values=$cluster \
            #Name=tag:aws:cloudformation:logical-id,Values=${nodetype} --output text | xargs echo
