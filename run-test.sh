#!/bin/bash

currentDir="$PWD"
echo "currentDir:" $currentDir

collection_file=scripts/tests-cases/profile-tests/APIM_Environment.postman_environment.json
environment_file=scripts/tests-cases/profile-tests/Profile_Setup_Tests.postman_collection.json
ip=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq ".status.loadBalancer.ingress[0].ip")
echo "ip:" $ip

/var/lib/jenkins/node-v18.17.0-linux-x64/bin/newman run "$collection_file" --environment "$environment_file" --env-var "cluster_ip=$ip" --insecure
