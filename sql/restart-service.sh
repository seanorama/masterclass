export PASSWORD=admin
export PORT=8080

#
# Use the API and jq to extract the clustername for a given machine
# Note: It will always take the first clustername !
#
function get_cluster_name {
	HOST=$1
	PORT=$2
	PASSWORD=$3
	NAME=$(curl -s -u admin:${PASSWORD} -H 'X-Requested-By: ambari' http://${HOST}:${PORT}/api/v1/clusters | jq -r .items[0].Clusters.cluster_name)
	if [ "$NAME" = "" ]; then
		exit 1
	else
		echo $NAME
		exit 0
	fi
}

#
# Set state to "INSTALLED" == stop service
#
function stop_service {
	HOST=$1
	PORT=$2
	PASSWORD=$3
	CLUSTER=$4
	SERVICE=$5
	# echo admin:${PASSWORD} 'X-Requested-By: ambari' http://${HOST}:${PORT}/api/v1/clusters/${CLUSTER}/services/${SERVICE} PUT '{"RequestInfo": {"context" :"Stop '${SERVICE}' via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}'
	curl -u admin:${PASSWORD} -H 'X-Requested-By: ambari' http://${HOST}:${PORT}/api/v1/clusters/${CLUSTER}/services/${SERVICE} -X PUT -d '{"RequestInfo": {"context" :"Stop '${SERVICE}' via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}'
}

#
# Set state to "STARTED" == start service
#
function start_service {
	HOST=$1
	PORT=$2
	PASSWORD=$3
	CLUSTER=$4
	SERVICE=$5
	# echo admin:${PASSWORD} 'X-Requested-By: ambari' http://${HOST}:${PORT}/api/v1/clusters/${CLUSTER}/services/${SERVICE} PUT '{"RequestInfo": {"context" :"Start '${SERVICE}' via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'
	curl -u admin:${PASSWORD} -H 'X-Requested-By: ambari' http://${HOST}:${PORT}/api/v1/clusters/${CLUSTER}/services/${SERVICE} -X PUT -d '{"RequestInfo": {"context" :"Start '${SERVICE}' via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'
}

function get_state {
	HOST=$1
	PORT=$2
	PASSWORD=$3
	CLUSTER=$4
	SERVICE=$5
	RESULT=$(curl -s -u admin:${PASSWORD} -H "X-Requested-By: ambari" http://${HOST}:${PORT}/api/v1/clusters/${CLUSTER}/services/${SERVICE} | jq -r .ServiceInfo.state)
	echo $RESULT
}

#
# Sufficient parameters?
#
if [ "$5" = "" ]; then
	echo -e "\nUsage: $(basename $0) AmbariHost AmbariPort AdminPassword start/stop [-w] Service(s)\n"
	echo -e "Service: HDFS YARN MAPREDUCE2 HIVE TEZ HCATALOG WEBHCAT ZOOKEEPER OOZIE PIG SQOOP ZOOKEEPER ...."
	echo -e "\nExample (wait until all are stopped, but don't wait for starts"
	echo -e "  ./$(basename $0) 192.168.56.131 8080 admin stop -w HBASE HIVE MAPREDUCE2 YARN HDFS ZOOKEEPER"
	echo -e "  ./$(basename $0) 192.168.56.131 8080 admin start   ZOOKEEPER HDFS YARN MAPREDUCE2 HIVE HBASE\n"
	exit 1
fi

#
# save parameters
#
HOST=$1
shift
PORT=$1
shift
PASSWORD=$1
shift
ACTION=$1
shift

if [ $1 == "-w" ]; then 
	WAIT=1
	shift
else
	WAIT=0
fi

[[ $ACTION == "start" ]] && CRIT="STARTED" || CRIT="INSTALLED"

#
# get cluster name
#
NAME=$(get_cluster_name $HOST $PORT $PASSWORD)
if [ $? -eq 0 ]; then
	#
	# and loop across all services given
	#
	for SERVICE in $@; do
		echo ""
		if [ $ACTION == "stop" ]; then
			echo "==> Trigger stopping of $SERVICE"
			stop_service $HOST $PORT $PASSWORD $NAME $SERVICE
		else
			echo "==> Trigger starting of $SERVICE"
			start_service $HOST $PORT $PASSWORD $NAME $SERVICE
		fi
		sleep 1
		LAST_SERVICE=$SERVICE
	done
fi

echo ""
echo -n "Waiting "

while [ $WAIT -eq 1 ]; do
	echo -n "."

	STATE=$(get_state $HOST $PORT $PASSWORD $NAME $LAST_SERVICE)
	if [ "$STATE" == "$CRIT" ]; then
		echo -e "\nDone"
		WAIT=0
	fi
	sleep 5
done
