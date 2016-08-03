#!/bin/bash

#start a postgres database with different combination of names, users, ports and passwords
MY_DIR="$(dirname "$0")"

source ${MY_DIR}/utils.sh

readonly KONG_API_DB_CONTAINER_NAME=kong-database
readonly KONG_API_CONTAINER_NAME=kong-api


testKongDockerImage(){
	local dbName=$1
	local dbUser=$2
	local dbPassword=$3
	local dbPort=$4
	echo "===================================="
	echo "Testing with $1 $2 $3 $4"
	echo "===================================="
	startKongDatabase $1 $2 $3 $4 ${KONG_API_DB_CONTAINER_NAME}
	startKongApiGateway $1 $2 $3 $4 ${KONG_API_CONTAINER_NAME}
}

testKongDockerImage kong kong kong 5432
testKongDockerImage kong kong kong 5431
testKongDockerImage kong kong kong123 5431
testKongDockerImage kong kongUser kong123 5431
testKongDockerImage kong-DB kongUser kong123 5431
