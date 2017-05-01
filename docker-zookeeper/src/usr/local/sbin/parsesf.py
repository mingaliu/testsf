#!/usr/bin/env python

import sys
import os
import json
import ast
import time

#print sys.argv[1] 
#print sys.argv[2] 

class NodeIP():
    "Stores nodeid and place pairs"
    def __init__(self, nodeid, ip):
        self.nodeid = nodeid
        self.ip = ip
		
def getJsonProperty(jsonstring, propertyName, startpos):
	pos = jsonstring.find(propertyName, startpos)
	id1 = jsonstring.find('\'', pos)
	id2 = jsonstring.find('\'', id1+ 2)
	return jsonstring[id1+1:id2]

def getIpAddress(jsonstring, startpos):
	id1 = jsonstring.find('tcp', startpos)
	id2 = jsonstring.find(':', id1+ 5)
	return jsonstring[id1+10:id2]
	
def getPartitionId(serviceresolveResult):
	# find the first data: position
	firstdata = serviceresolveResult.find('data:', 0)
   
	lastinfo= serviceresolveResult.find('info:', firstdata)
   
	jsonstring = serviceresolveResult[firstdata:lastinfo]
   
	# replace data: with empty string
	jsonstring=jsonstring.replace('data:', '')
	#sys.stderr.write(ast.literal_eval(jsonstring))
	#jdata = json.loads(ast.literal_eval(jsonstring))
   
	#return jdata['partitionInformation']['id']

	idpos = jsonstring.find('partitionInformation')  
	return getJsonProperty(jsonstring, 'id', idpos) 

def findNodeId(jsonstring, pos):
	nodename= getJsonProperty(jsonstring, 'nodeName', pos)
	lastunderscore=nodename.rfind('_')
	nodeid=nodename[lastunderscore+1:]
	if nodename[lastunderscore-1].isdigit():
		nodeid=nodename[lastunderscore-1]+nodeid	
	return nodeid
	
def findAllNodeIP(jsonstring):
	allnodes = []
	pos = jsonstring.find('Endpoint1', 0)

	while pos != -1:
		ep = getIpAddress(jsonstring, pos) 
		nodeid = findNodeId(jsonstring, pos) 
		allnodes.append(NodeIP(nodeid, ep))
	
		pos = jsonstring.find('Endpoint1', pos + 10)
	
	sys.stderr.write('python end findAllNodeIP' + '\n')
	return allnodes
	
def setZookerIP(replicaresult, instancecount, serviceEnum):
	sys.stderr.write("start setZookerIP\n")
	instancecount = int(instancecount)
	serviceEnum = int(serviceEnum)

	# find the first data: position
	firstdata = replicaresult.find('data:', 0)
	lastinfo= replicaresult.find('info:', firstdata)
   
	jsonstring = replicaresult[firstdata:lastinfo]
	# replace data: with empty string
	jsonstring=jsonstring.replace('data:', '')

	allNodes = findAllNodeIP(jsonstring)
	
	if len(allNodes) < instancecount:
		sys.stderr.write(str(len(allNodes)) + " < " + instancecount + "not ready, retry\n")
		return "Not Ready"
	
	result=''
	kafkazookeperIp=''
	for node in allNodes:
		if serviceEnum == 1:
			result+='ZOOKEEPER_SERVER_'+node.nodeid + '=' +  node.ip + ' '
		elif serviceEnum == 2:
			if kafkazookeperIp == '':
				kafkazookeperIp = node.ip
			else:
				kafkazookeperIp = kafkazookeperIp + ',' + node.ip

	if serviceEnum == 2:
		result+='ZOOKEEPER_IP=' +  kafkazookeperIp + ' '

	sys.stderr.write("python keyvaluepir:" + result)
	sys.stderr.write("\nend setZookerIP\n")
	return result
   
 
# main entry function.
result=''
if sys.argv[1] == 'getPartitionId':
	result=getPartitionId(sys.argv[2])
elif sys.argv[1] == 'setZookerIP':
	result=setZookerIP(sys.argv[2], sys.argv[3], sys.argv[4])
	
print result

