
# todo: move to the dockerfile.
# sudo npm install --global azure-cli@0.10.12

# those are set in container
 export Fabric_NodeIPOrFQDN=10.0.1.4
 export Fabric_NodeName=_backend_1
 export Fabric_ApplicationName=fabric:/tenantA/KafkaApp

serviceName=$1

echo "serviceName=" ${serviceName}

# is set Fabric_NodeIPOrFQDN/Fabric_NodeName
echo "start connect" ${Fabric_NodeIPOrFQDN}

if [ "$serviceName" = "zookeeper" ] 
then
	zookerInstanceCount=1
	azure servicefabric cluster connect http://${Fabric_NodeIPOrFQDN}:19080

	# ZOOKEEPER_ID is the last digit of Fabric_NodeName
	export ZOOKEEPER_ID=${Fabric_NodeName##*_}
	echo "ZOOKEEPER_ID set to " ${ZOOKEEPER_ID}

	# find all zookeeper instances
	servicersolve=$(azure servicefabric service resolve --service-name ${Fabric_ApplicationName}/zookeeper1)
	#echo azure output ${servicersolve}
	
	partitionId=$(python parsesf.py getPartitionId "$servicersolve")
	
	echo python getpartitionId ${partitionId}
	
	replicaResult=$(azure servicefabric replica show --partition-id ${partitionId})
	#echo python getpartitionId ${replicaResult}

	keyvaluepair=''
	while true; do
		keyvaluepair=$(python parsesf.py setZookerIP "$replicaResult" $zookerInstanceCount 1)
		if [ "$keyvaluepair" = "Not Ready" ]
		then
			sleep 1s
		else
			break
		fi
	done
	
	declare -A vars=( )
	for kvp in $keyvaluepair; do
		set -- `echo $kvp | tr '=' ' '`
		key=$1
		value=$2
		vars[${key}]=${value}
		declare ${key}=${value}
		echo ${key} "=" ${value}
	done
    

elif  [ "$serviceName" = "kafka" ] 
then
	zookerInstanceCount=1
	azure servicefabric cluster connect http://${Fabric_NodeIPOrFQDN}:19080

	# KAFKA_BROKER_ID is the last digit of Fabric_NodeName
	export KAFKA_BROKER_ID=${Fabric_NodeName##*_}
	export KAFKA_ADVERTISED_HOST_NAME=${Fabric_NodeIPOrFQDN}
	echo "KAFKA_BROKER_ID set to " ${KAFKA_BROKER_ID}
	
	# find all zookeeper instances
	servicersolve=$(azure servicefabric service resolve --service-name ${Fabric_ApplicationName}/zookeeper1)
	#echo azure output ${servicersolve}
	
	partitionId=$(python parsesf.py getPartitionId "$servicersolve")
	
	echo python getpartitionId ${partitionId}
	
	replicaResult=$(azure servicefabric replica show --partition-id ${partitionId})
	echo get replicaResult ${replicaResult}
	
	keyvaluepair=$(python parsesf.py setZookerIP "$replicaResult" $zookerInstanceCount 2)
	
	declare -A vars=( )
	for kvp in $keyvaluepair; do
		set -- `echo $kvp | tr '=' ' '`
		key=$1
		value=$2
		vars[${key}]=${value}
		declare ${key}=${value}
		echo ${key} "=" ${value}
	done
else
	echo "Unknown parameter"
fi





