#! /usr/bin/env bash
set -x

postfix=$(date +'%Y-%m-%d')
containername=presto$postfix

Fabric_NodeIPOrFQDN=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')

#1. build
sudo docker build -t $containername .

sudo docker stop "prestocoordinator"
sudo docker stop "prestoworker" 
sudo docker rm "prestocoordinator"
sudo docker rm "prestoworker"

#2. Setup local three node zookeeper cluster
sudo docker run -d -p 8080:8080 --name "prestocoordinator" -e PRESTO_ISCOORDINATOR=true -e Fabric_NodeIPOrFQDN=$Fabric_NodeIPOrFQDN $containername
sudo docker run -d -p 8081:8081 --name "prestoworker" -e PRESTO_ISCOORDINATOR=false -e Fabric_NodeIPOrFQDN=$Fabric_NodeIPOrFQDN $containername

# sleep to make sure the docker is started probably
sleep 30

#3. Run presto client again local cluster and verify it is working
sudo docker run --entrypoint "/usr/local/presto/presto"  --rm $containername --server $Fabric_NodeIPOrFQDN:8080 --catalog jmx --schema jmx --execute 'SELECT * FROM system.runtime.nodes'

NODESNUMBER=$(sudo docker run --entrypoint "/usr/local/presto/presto"  --rm $containername --server $Fabric_NodeIPOrFQDN:8080 --catalog jmx --schema jmx --execute 'SELECT count(*) FROM system.runtime.nodes')

if [ "$NODESNUMBER" != "\"2\"" ]; then
	echo "${red} Test Failed"
	exit -1
else 
	echo "Test succeed!"
fi

#4. Test the termination handler:
sudo docker kill --signal="SIGTERM" prestoworker
sleep 20

Exitcode=$(sudo docker inspect -f '{{.State.ExitCode}}' prestoworker)
if [ "$Exitcode" != "143" ]; then
	echo "${red} Test Failed for exit code"
	exit -1
else 
	echo "Test succeed!"
fi



