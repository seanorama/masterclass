#for fruitycluster in apple apricot banana blackberry blackcurrant blueberry coconut cherry clementine cranberry damson elderberry fig gooseberry grape guava huckleberry lemon lime lychee mango melon nectarine orange passionfruit peach pear plum prune pineapple pomegranate raspberry satsuma strawberry tangerine 

for fruitycluster in fig

do

  echo "####################################################"
  \n
  echo "This is the $fruitycluster cluster"
  \n
  echo "This is the Ambari Node"
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PublicDnsName]' --filters Name=instance-state-name,Values=running Name=tag:aws:cloudformation:stack-name,Values=$fruitycluster Name=tag:aws:cloudformation:logical-id,Values=AmbariNode --output text
  \n
  echo "These are the Master Nodes"
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PublicDnsName]' --filters Name=instance-state-name,Values=running Name=tag:aws:cloudformation:stack-name,Values=$fruitycluster Name=tag:aws:cloudformation:logical-id,Values=MasterNodes --output text
  \n
  echo "These are the Data Nodes"
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PublicDnsName]' --filters Name=instance-state-name,Values=running Name=tag:aws:cloudformation:stack-name,Values=$fruitycluster Name=tag:aws:cloudformation:logical-id,Values=WorkerNodes --output text
  \n
done