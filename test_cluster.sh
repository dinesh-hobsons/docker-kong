#!/bin/bash

set -e
#Tests a kong cluster
#Create a cluster of 3 kong servers
#front it with a nginx load balancer
MY_DIR="$(dirname "$0")"

source ${MY_DIR}/utils.sh

setupCluster(){
local dbName=kongDb
local dbUser=kongUser
local dbPassword=kongPwd
local dbPort=5432
local dbContainerName=kong-db
local kongContainerNamePrefix=kong-api

#start database
logLabel "Setup Kong Database"
startKongDatabase ${dbName} ${dbUser} ${dbPassword} ${dbPort} ${dbContainerName}

#set up cluster
for ((i=1; i<=3; i++)); do
    logLabel "Setup Kong $i"
    startKongApiGateway ${dbName} ${dbUser} ${dbPassword} ${dbPort} ${kongContainerNamePrefix}-$i
done

logLabel "Setup loadBalancer"
docker rm -f ${kongContainerNamePrefix}
#start loadbalancer
local dockerHostIp=$(getDockerHost)

docker run  -d   \
    --name ${kongContainerNamePrefix}  \
      -p "8001:80"    \
      --link "kong-api-1:${kongContainerNamePrefix}-1"  \
      --link "kong-api-2:${kongContainerNamePrefix}-2"  \
      --link "kong-api-3:${kongContainerNamePrefix}-3"  \
      --env-file=./env.list \
      jasonwyatt/nginx-loadbalancer:latest

    echo "wait until kong api is online"
    local kongAdminPort=$(getContainerPort ${kongContainerNamePrefix} 80/tcp)

    local response=-1
    until [[ ${response} == *"200"* ]]; do
        response=$(curl -w %{http_code} \
                    -i \
                    -X GET http://${dockerHostIp}:${kongAdminPort}/apis) || true
        echo  "kong api ${response}"
        sleep 5
        exitIfContainerIsDead ${kongContainerNamePrefix}
    done
}

setupCluster

serverCount=$(curl http://localhost:8001/cluster | python -mjson.tool | grep total | cut -d: -f2)
if [ ${serverCount} -ne 3 ]
then
   echo "Error: expected 3 kong servers to be alive, got ${serverCount}"
fi

clusterCount=$(curl http://localhost:8001/cluster | python -mjson.tool | grep -c "status\": \"alive")
if [ $clusterCount -ne 3 ]
then
   echo "Error: expected 3 kong servers to be alive, got ${clusterCount}"
fi


#register api
curl -XPOST \
    http://localhost:8001/apis \
    -d "name=google&upstream_url=http://www.google.com&request_path=/google&strip_request_path=true"
#check against each server

for ((i=1; i<=3; i++)); do
    port=$(docker port kong-api-$i 8001/tcp)
    response=$(curl http://$port/apis | python -mjson.tool | grep name | cut -d\" -f4)
    if [ ${response} != "google" ]
    then
        logError "Expected google, got $response"
    else
        logInfo "API registered"
    fi
done





