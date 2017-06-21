#! /usr/bin/env bash

# Fail hard and fast
set -eo pipefail


    azure telemetry --disable
    azure servicefabric cluster connect http://${Fabric_NodeIPOrFQDN}:19080

    # ZOOKEEPER_ID is the last digit of Fabric_NodeName
    NUMBER1=${Fabric_NodeName##*_}
	REMOVEUNDER=${Fabric_NodeName%_*}
	NUMBER2=${REMOVEUNDER: -1}
	
	regulare='^[0-9]+$'
	if ! [[ $NUMBER2 =~ $regulare ]] ; 
	then
		ZOOKEEPER_ID=$NUMBER1
	else
		ZOOKEEPER_ID=$NUMBER2$NUMBER1
	fi
	
	echo "ZOOKEEPER_ID set to " ${ZOOKEEPER_ID}  

    # find all zookeeper instances
    servicersolve=$(azure servicefabric service resolve --service-name ${Fabric_ApplicationName}/zookeeper1)
    #echo azure output ${servicersolve}
    
    partitionId=$(python $PYTHONSCRIPT getPartitionId "$servicersolve")
    
    echo python getpartitionId ${partitionId}
    
    replicaResult=$(azure servicefabric replica show --partition-id ${partitionId})
    #echo python getpartitionId ${replicaResult}

    keyvaluepair=''
    while true; do
        keyvaluepair=$(python $PYTHONSCRIPT setZookerIP "$replicaResult" $ZOOKEEPER_INSTANCECOUNT 1)
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
 
MYDIR="$(dirname "$0")"
PYTHONSCRIPT="$MYDIR/configzookeeper.py"

# invoke python to get the config value in formation x=value;y=value;z=value
keyvaluepair=''
while true; do
	keyvaluepair=$(python $PYTHONSCRIPT setZookerIP "$replicaResult" $ZOOKEEPER_INSTANCECOUNT 1)
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
	
# Start to set all config for zookeeper
echo $ZOOKEEPER_ID > /var/lib/zookeeper/myid

ZOOKEEPER_TICK_TIME=${ZOOKEEPER_TICK_TIME:-2000}
echo "tickTime=${ZOOKEEPER_TICK_TIME}" > /opt/zookeeper/conf/zoo.cfg
echo "tickTime=${ZOOKEEPER_TICK_TIME}"

ZOOKEEPER_INIT_LIMIT=${ZOOKEEPER_INIT_LIMIT:-10}
echo "initLimit=${ZOOKEEPER_INIT_LIMIT}" >> /opt/zookeeper/conf/zoo.cfg
echo "initLimit=${ZOOKEEPER_INIT_LIMIT}"

ZOOKEEPER_SYNC_LIMIT=${ZOOKEEPER_SYNC_LIMIT:-5}
echo "syncLimit=${ZOOKEEPER_SYNC_LIMIT}" >> /opt/zookeeper/conf/zoo.cfg
echo "syncLimit=${ZOOKEEPER_SYNC_LIMIT}"

ZOOKEEPER_DATADIR=${ZOOKEEPER_DATADIR:"dataDir=/var/lib/zookeeper"}
echo "dataDir=${ZOOKEEPER_DATADIR}" >> /opt/zookeeper/conf/zoo.cfg
echo "dataDir=${ZOOKEEPER_DATADIR}"

ZOOKEEPER_DATALOGDIR=${ZOOKEEPER_DATALOGDIR:"dataDir=/var/lib/zookeeper"}
echo "dataLogdir=${ZOOKEEPER_DATALOGDIR}" >> /opt/zookeeper/conf/zoo.cfg
echo "dataLogdir=${ZOOKEEPER_DATALOGDIR}"

ZOOKEEPER_CLIENTPORT=${ZOOKEEPER_CLIENTPORT:2181}
echo "clientPort=${ZOOKEEPER_CLIENTPORT}" >> /opt/zookeeper/conf/zoo.cfg
echo "clientPort=${ZOOKEEPER_CLIENTPORT}"

ZOOKEEPER_CLIENT_CNXNS=${ZOOKEEPER_CLIENT_CNXNS:-60}
echo "maxClientCnxns=${ZOOKEEPER_CLIENT_CNXNS}" >> /opt/zookeeper/conf/zoo.cfg
echo "maxClientCnxns=${ZOOKEEPER_CLIENT_CNXNS}"

ZOOKEEPER_AUTOPURGE_SNAP_RETAIN_COUNT=${ZOOKEEPER_AUTOPURGE_SNAP_RETAIN_COUNT:-3}
echo "autopurge.snapRetainCount=${ZOOKEEPER_AUTOPURGE_SNAP_RETAIN_COUNT}" >> /opt/zookeeper/conf/zoo.cfg
echo "autopurge.snapRetainCount=${ZOOKEEPER_AUTOPURGE_SNAP_RETAIN_COUNT}"

ZOOKEEPER_AUTOPURGE_PURGE_INTERVAL=${ZOOKEEPER_AUTOPURGE_PURGE_INTERVAL:-0}
echo "autopurge.purgeInterval=${ZOOKEEPER_AUTOPURGE_PURGE_INTERVAL}" >> /opt/zookeeper/conf/zoo.cfg
echo "autopurge.purgeInterval=${ZOOKEEPER_AUTOPURGE_PURGE_INTERVAL}"

for VAR in "${!vars[@]}" 
do
  if [[ $VAR =~ ^ZOOKEEPER_SERVER_.* ]]; then
	SERVER_ID=${VAR##*_}
    SERVER_IP=${vars[$VAR]}
    if [ "${SERVER_ID}" = "${ZOOKEEPER_ID}" ]; then
      echo "server.${SERVER_ID}=0.0.0.0:2888:3888" >> /opt/zookeeper/conf/zoo.cfg
      echo "server.${SERVER_ID}=0.0.0.0:2888:3888"
    else
      echo "server.${SERVER_ID}=${SERVER_IP}:2888:3888" >> /opt/zookeeper/conf/zoo.cfg
      echo "server.${SERVER_ID}=${SERVER_IP}:2888:3888"
    fi
  fi
done

su zookeeper -s /bin/bash -c "/opt/zookeeper/bin/zkServer.sh start-foreground"


