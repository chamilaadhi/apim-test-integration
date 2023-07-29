#!/bin/bash

currentDir="$PWD"
echo "currentDir:" $currentDir
reldir=`dirname $0`

ip=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq ".status.loadBalancer.ingress[0].ip")
trimmed_string=${ip#\"}    # Remove leading double quote
ip=${trimmed_string%\"}  
echo "ip:" $ip

analytics_collection_file=$reldir/tests-cases/analytics-tests/analytics_test.json
analytics_environment_file=$reldir/tests-cases/analytics-tests/analytics_environment.json
 
newman run "$analytics_collection_file" \
  --environment "$analytics_environment_file" \
  --env-var "cluster_ip=${ip}" \
  --insecure \
  --reporters cli,junit \
  --reporter-junit-export newman-analytics-results.xml

collection_file=$reldir/tests-cases/profile-tests/Profile_Setup_Tests.postman_collection.json
environment_file=$reldir/tests-cases/profile-tests/APIM_Environment.postman_environment.json

newman run "$collection_file" \
  --environment "$environment_file" \
  --env-var "cluster_ip=${ip}" \
  --insecure \
  --reporters cli,junit \
  --reporter-junit-export newman-results.xml
