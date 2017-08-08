#!/bin/bash
set -e

#contains kong utilities
readonly BOLD=`tput bold`
readonly RED=${txtbld}$(tput setaf 1)
readonly YELLOW=${txtbld}$(tput setaf 2)
readonly RESET=`tput sgr0`

logError() {
    echo "${BOLD}${RED}======================================================${RESET}"
    echo "${BOLD}${RED}$1${RESET}"
    echo "${BOLD}${RED}======================================================${RESET}"
}

logLabel() {
    echo "${BOLD}${YELLOW}======================================================${RESET}"
    echo "${BOLD}${YELLOW}$1${RESET}"
    echo "${BOLD}${YELLOW}======================================================${RESET}"
}

logInfo() {
    echo $1
}

getDockerHost() {
    local unameStr=`uname`
    if [[ "$unameStr" == 'Linux' ]]; then
            local dockerHostIp=$(ip route get 1 | awk '{print $NF;exit}')
    else
            local dockerHostIp=$(docker-machine ip)
            if [ -z "$dockerHostIp" ]
            then
                #likely docker for mac is used
                local dockerHostIp=$(ifconfig en0 | grep inet | grep -v inet6 | cut -d' ' -f2)
            fi
    fi
	echo ${dockerHostIp}
}

killContainer(){
	local containerName=$1
	docker rm -f ${containerName} || true
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

    echo "Starting Kong DB"

    local dockerHostIp=$(getDockerHost)
    local postgresDockerImageName=postgres:9.5
 	local dbName=$1
	local dbUser=$2
	local dbPassword=$3
	local dbPort=$4
	local containerName=$5
    killContainer ${containerName}

    echo "Starting kong database"
    docker run -d --name ${containerName} \
                    -p "$dbPort:5432"\
                    -e "POSTGRES_DB=$dbName" \
                    -e "POSTGRES_USER=$dbUser" \
                    -e "POSTGRES_PASSWORD=$dbPassword" \
                    ${postgresDockerImageName}

    local postgresPort=$(getContainerPort ${containerName} 5432/tcp)
    local responseCode=-1
    until [[ ${responseCode} -eq 0 ]]; do
        nc -z ${dockerHostIp} ${postgresPort} < /dev/null
        responseCode=$?
        sleep 5
        exitIfContainerIsDead ${containerName}
    done
}

startKongApiGateway() {
	local dbName=$1
	local dbUser=$2
	local dbPassword=$3
	local dbPort=$4
	local containerName=$5
    local dockerHostIp=$(getDockerHost)
    local kongDockerImageName=turbo-registry2.hobsonshighered.com/starfish-kong:latest

    killContainer ${containerName}
    echo "Start kong-api gateway $containerName"
    docker run -t -d --name ${containerName} \
        -e "DATABASE=postgres" \
        -e "DATABASE_NAME=$dbName" \
        -e "DATABASE_PORT=$dbPort" \
        -e "DATABASE_USER=$dbUser" \
        -e "DATABASE_PASSWORD=$dbPassword" \
        -e "DATABASE_HOST=$dockerHostIp" \
        -P \
        ${kongDockerImageName}

    echo "wait until kong api is online"
    local kongAdminPort=$(getContainerPort ${containerName} 8001/tcp)

    local response=-1
    until [[ ${response} == *"200"* ]]; do
        response=$(curl -w %{http_code} \
                    -i \
                    -X GET http://${dockerHostIp}:${kongAdminPort}/apis) || true
        echo  "kong api ${response}"
        sleep 5
        exitIfContainerIsDead ${containerName}
    done
}
