#!/bin/bash
set -e
docker build -t turbo-registry2.hobsonshighered.com/starfish-kong:0.8.3 .
docker tag turbo-registry2.hobsonshighered.com/starfish-kong:0.8.3 turbo-registry2.hobsonshighered.com/starfish-kong:latest
./test_setup.sh && ./test_cluster.sh 
