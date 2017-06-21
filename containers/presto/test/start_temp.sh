#! /usr/bin/env bash

containername=0620
Fabric_NodeIPOrFQDN=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')

NODESNUMBER=$(sudo docker run --entrypoint "/usr/local/presto/presto" --rm $containername --server $Fabric_NodeIPOrFQDN:8080 --catalog jmx --schema jmx --execute 'SELECT count(*) FROM system.runtime.nodes')

echo "it is [$NODESNUMBER]"
#a="abc"
#if [ "$a" == "abc" ]; then
if [ "$NODESNUMBER" == "\"2\"" ]; then
	echo "${red} Failed"
	exit -1
fi



