# Instructor notes
========================================

## Deploy clusters on AWS

See ../generic/README-INSTRUCTOR.md for more details

```

cd ../generic

export AWS_DEFAULT_REGION=eu-west-1  ## region to deploy in
export lab_prefix=summit         ## template for naming the cloudformation stacks
export lab_first=100                 ## number to start at in naming
export lab_count=1                   ## number of clusters to create

export cfn_parameters='
[
  {"ParameterKey":"KeyName","ParameterValue":"secloud"},
  {"ParameterKey":"SubnetId","ParameterValue":"subnet-7e49641b"},
  {"ParameterKey":"SecurityGroups","ParameterValue":"sg-f915bc9d"},
  {"ParameterKey":"AdditionalInstanceCount","ParameterValue":"0"},
  {"ParameterKey":"PostCommand","ParameterValue":"curl -ksSL https://raw.githubusercontent.com/seanorama/masterclass/master/single-view/scripts/00_prep_host.sh | bash"},
  {"ParameterKey":"InstanceType","ParameterValue":"m4.2xlarge"},
  {"ParameterKey":"BootDiskSize","ParameterValue":"100"}
]
'

```

## Distribute cluster details to participants:

Populate lab list:

1. Execute:
```
../bin/clusters-report-flat.sh
```

2. Paste into a shared notepad. My personal one is: http://j.mp/summit-labs
3. Distribute link to participants and ask them to claim their custers

## Follow labs in LABS.md
