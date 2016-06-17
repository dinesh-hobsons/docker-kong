#!/bin/bash
docker build -t docker-east1.hobsons-labs.com/kong:0.8.3 .
docker tag docker-east1.hobsons-labs.com/kong:0.8.3 docker-east1.hobsons-labs.com/kong:latest
./test_setup.sh && docker push docker-east1.hobsons-labs.com/kong:latest
