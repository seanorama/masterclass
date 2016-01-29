#!/usr/bin/env bash

aws cloudformation create-stack --stack-name sqltest \
    --capabilities CAPABILITY_IAM \
    --template-body file://./cloudformation.json \
    --parameters ParameterKey=KeyName,ParameterValue=secloud \
      ParameterKey=PostScript,ParameterValue='export cluster_name=$stack; curl -sSL https://raw.githubusercontent.com/seanorama/masterclass/master/sql/setup.sh | bash'


lab_count=${lab_count:-2}
lab_prefix=${lab_prefix:-test}

ip=$(curl -s4 icanhazip.com)/32
aws ec2 authorize-security-group-ingress \
    --group-id sg-f915bc9d \
    --ip-permissions \
        '[{"IpProtocol": "icmp", "FromPort": -1, "ToPort": -1, "IpRanges": [{"CidrIp": "'${ip}'"}]},
          {"IpProtocol": "tcp",  "FromPort": 0, "ToPort": 65535, "IpRanges": [{"CidrIp": "'${ip}'"}]},
          {"IpProtocol": "udp",  "FromPort": 0, "ToPort": 65535, "IpRanges": [{"CidrIp": "'${ip}'"}]}]'


m4.xlarge

resources=$(aws ec2 run-instances \
    --count 1 \
    --image-id ami-25158352 \
    --instance-type m4.xlarge \
    --key-name masterclass \
    --subnet-id subnet-7e49641b \
    --associate-public-ip-address \
    | jq -r ".Instances[0].InstanceId")

#    --user-data file://userdata.sh

aws ec2 create-tags --resources "${resources}" ` --tags "Key=Name,Value=development_webserver"


exit

export lab_count=40
export lab_first=101
export lab_prefix=sto
source ~/src/ambari-bootstrap/providers/google/create-google-hosts.sh
create=true ~/src/ambari-bootstrap/providers/google/create-google-hosts.sh

exit


command="echo OK"; pdsh -w ${hosts_all} "${command}"

command="df -h /"
pdsh -w ${hosts_all} "${command}"


read -r -d '' command <<EOF
sudo yum -y -q install screen
curl -sSL -O https://raw.githubusercontent.com/seanorama/masterclass/master/security/setup.sh
chmod +x setup.sh
screen -S myscreen /home/student/setup.sh
EOF
pdsh -w ${hosts_all} "${command}"


for lab in ${labs}; do echo "${lab_prefix}${lab} "; done \
    | xargs echo gcloud compute instances delete


echo $hosts_hdp | awk 'BEGIN {RS=",";} {print $1}' | grep siq | xargs echo tmux-cssh -u student
