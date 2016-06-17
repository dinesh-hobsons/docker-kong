#!/bin/bash

#start a postgres database with different combination of names, users, ports and passwords

readonly KONG_API_DB_CONTAINER_NAME=kong-database
readonly KONG_API_CONTAINER_NAME=kong-api

getDockerHost() {
		local dockerHostIp="localhost"
    local unameStr=`uname`
    if [[ "$unameStr" == 'Linux' ]]; then
            local dockerHostIp=$(ip route get 1 | awk '{print $NF;exit}')
    else
            local dockerHostIp=$(docker-machine ip)
    fi
		echo ${dockerHostIp}
}

killContainer(){
	local containerName=$1
	docker stop ${containerName} || true
	docker rm ${containerName} || true
}

exitIfContainerIsDead() {
    local containerName=$1
    local containerId=$(docker ps | grep ${containerName})
    if [ -z "${containerId}" ]
    then
        echo "${containerName} has exited. Check for errors"
        docker logs ${containerName}
        exit 1
    fi
}

getContainerPort() {
    local containerName=$1
    local containerPort=$2
    local port=$(docker port \
                    ${containerName} ${containerPort} \
                    | cut -d: -f2)
    echo ${port}
}

startKongDatabase() {
    killContainer ${KONG_API_DB_CONTAINER_NAME}

    echo "Starting Kong DB"

    local dockerHostIp=$(getDockerHost)
    local postgresDockerImageName=docker-east1.hobsons-labs.com/postgres:9.5
 	local dbName=$1
	local dbUser=$2
	local dbPassword=$3
	local dbPort=$4

    echo "Starting kong database"
    docker run -d --name ${KONG_API_DB_CONTAINER_NAME} \
                    -p "$dbPort:5432"\
                    -e "POSTGRES_DB=$dbName" \
                    -e "POSTGRES_USER=$dbUser" \
                    -e "POSTGRES_PASSWORD=$dbPassword" \
                    ${postgresDockerImageName}

    local postgresPort=$(getContainerPort kong-database 5432/tcp)
    local responseCode=-1
    until [[ ${responseCode} -eq 0 ]]; do
        nc -z ${dockerHostIp} ${postgresPort} < /dev/null
        responseCode=$?
        sleep 5
        exitIfContainerIsDead ${KONG_API_DB_CONTAINER_NAME}
    done
}

startKongApiGateway() {
	local dbName=$1
	local dbUser=$2
	local dbPassword=$3
	local dbPort=$4
    local dockerHostIp=$(getDockerHost)
    local kongDockerImageName=docker-east1.hobsons-labs.com/kong:latest

    killContainer ${KONG_API_CONTAINER_NAME}
    echo "Start kong-api gateway $KONG_API_CONTAINER_NAME"
    docker run -t -d --name ${KONG_API_CONTAINER_NAME} \
        -e "DATABASE=postgres" \
        -e "DATABASE_NAME=$dbName" \
        -e "DATABASE_PORT=$dbPort" \
        -e "DATABASE_USER=$dbUser" \
        -e "DATABASE_PASSWORD=$dbPassword" \
        -e "DATABASE_HOST=$dockerHostIp" \
        -P \
        ${kongDockerImageName}

    echo "wait until kong api is online"
    local kongAdminPort=$(getContainerPort kong-api 8001/tcp)

    local response=-1
    until [[ ${response} == *"200"* ]]; do
        response=$(curl -w %{http_code} \
                    -i \
                    -X GET http://${dockerHostIp}:${kongAdminPort}/apis)
        echo  "kong api ${response}"
        sleep 5
        exitIfContainerIsDead ${KONG_API_CONTAINER_NAME}
    done
}

testKongDockerImage(){
	local dbName=$1
	local dbUser=$2
	local dbPassword=$3
	local dbPort=$4
	echo "===================================="
	echo "Testing with $1 $2 $3 $4"
	echo "===================================="
	startKongDatabase $1 $2 $3 $4
	startKongApiGateway $1 $2 $3 $4
}

testKongDockerImage kong kong kong 5432
testKongDockerImage kong kong kong 5431
testKongDockerImage kong kong kong123 5431
testKongDockerImage kong kongUser kong123 5431
testKongDockerImage kong-DB kongUser kong123 5431
