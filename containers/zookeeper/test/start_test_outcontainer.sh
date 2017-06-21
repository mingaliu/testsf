#! /usr/bin/env bash

postfix=$(date +'%Y-%m-%d')
containername=zookeeper$postfix

#1. build
sudo docker build -t $containername

#2. Setup local three node zookeeper cluster
docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 -e Fabric_NodeIPOrFQDN=10.0.1.14 -e Fabric_NodeName=_worker3_3 -e Fabric_ApplicationName=fabric:/tenantB/KafkaApp -e ZOOKEEPER_INSTANCECOUNT=3 $containername


#2. Run zookeeper client again local cluster
docker run --rm $containername bin/zkCli.sh -server 10.0.1.8:2181 | ls /brokers/ids

# verify zookeeper is running....
#docker run -i -t medined/docker-zookeeper-shell:3.4.6 /zookeeper-3.4.6/bin/zkCli.sh -server 10.0.0.10:2181
#ls /brokers/ids



