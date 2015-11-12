#!/bin/bash

PORT=$1
shift

cat <<EOF > /tmp/doit.sh
#!/bin/bash

sudo sh -c "echo 'client.api.port=${PORT}' >> /etc/ambari-server/conf/ambari.properties"
sudo TERM=xterm ambari-server restart 
sudo TERM=xterm ambari-agent restart
EOF

for IP in $@; do
	echo "===> $IP <===="
	scp /tmp/doit.sh centos@$IP:/tmp
	ssh centos@$IP chmod 777 /tmp/doit.sh
	ssh -f centos@$IP '/tmp/doit.sh'
	echo "waiting ..."
	sleep 30
	echo "... done"
done