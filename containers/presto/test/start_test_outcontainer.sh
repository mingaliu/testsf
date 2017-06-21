#! /usr/bin/env bash

postfix=$(date +'%Y-%m-%d')
containername=presto$postfix

Fabric_NodeIPOrFQDN=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')

#1. build
sudo docker build -t $containername .

#2. Setup local three node zookeeper cluster
sudo docker run -d -p 8080:8080 -e PRESTO_ISCOORDINATOR=true -e Fabric_NodeIPOrFQDN=$Fabric_NodeIPOrFQDN $containername
sudo docker run -d -p 8081:8081 -e PRESTO_ISCOORDINATOR=false -e Fabric_NodeIPOrFQDN=$Fabric_NodeIPOrFQDN $containername

#3. Run presto client again local cluster and verify it is working
sudo docker run --entrypoint "/usr/local/presto/presto"  --rm $containername --server $Fabric_NodeIPOrFQDN:8080 --catalog jmx --schema jmx --execute 'SELECT * FROM system.runtime.nodes'

NODESNUMBER=$(sudo docker run --entrypoint "/usr/local/presto/presto"  --rm $containername --server $Fabric_NodeIPOrFQDN:8080 --catalog jmx --schema jmx --execute 'SELECT count(*) FROM system.runtime.nodes')

if [ "$NODESNUMBER" != "\"2\"" ]; then
	echo "${red} Test Failed"
	exit -1
else 
	echo "Test succeed!"
fi


