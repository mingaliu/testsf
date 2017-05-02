#!/bin/bash -x

#For test, set Fabric_NodeIPOrFQDN=10.0.01

export SPARK_CONF_DIR=${SPARK_CONF_DIR:-50}
echo "SPARK_CONF_DIR=${SPARK_CONF_DIR}" > conf/spark-env.sh
echo "SPARK_CONF_DIR=${SPARK_CONF_DIR}"

export SPARK_PUBLIC_DNS=${Fabric_NodeIPOrFQDN:-50}
echo "SPARK_PUBLIC_DNS=${SPARK_PUBLIC_DNS}" >> conf/spark-env.sh
echo "SPARK_PUBLIC_DNS=${SPARK_PUBLIC_DNS}"

#SPARK_MASTER_HOST=${SPARK_MASTER_HOST:-50}
#echo "SPARK_MASTER_HOST=${SPARK_MASTER_HOST}" >> conf/spark-env.sh
#echo "SPARK_MASTER_HOST=${SPARK_MASTER_HOST}"

#SPARK_LOCAL_IP=${SPARK_LOCAL_IP:-50}
#echo "SPARK_LOCAL_IP=${SPARK_LOCAL_IP}" >> conf/spark-env.sh
#echo "SPARK_LOCAL_IP=${SPARK_LOCAL_IP}"

#if it is worker, let's figure out the master IP address
if [ "$MASTERORSLAVE" = "org.apache.spark.deploy.worker.Worker" ]
then
	MYDIR="$(dirname "$0")"
    PYTHONSCRIPT="$MYDIR/parsesf.py"

	azure telemetry --disable
	azure servicefabric cluster connect http://${Fabric_NodeIPOrFQDN}:19080

	# find sparkmaster instances
	servicersolve=$(azure servicefabric service resolve --service-name ${Fabric_ApplicationName}/SparkMaster)
	#echo azure output ${servicersolve}
	
	partitionId=$(python $PYTHONSCRIPT getPartitionId "$servicersolve")
	
	echo python getpartitionId ${partitionId}
	
	replicaResult=$(azure servicefabric replica show --partition-id ${partitionId})
	echo get replicaResult ${replicaResult}

		keyvaluepair=''
	while true; do
		keyvaluepair=$(python $PYTHONSCRIPT setZookerIP "$replicaResult" 1 3)
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
	
	if [ -z "$MASTERURI" ];
	then 
		echo MASTERURI is not set, wait and exit to make debug easier ...
		sleep 15m	
	fi
fi

exec bin/spark-class ${MASTERORSLAVE}  ${MASTERURI}	


