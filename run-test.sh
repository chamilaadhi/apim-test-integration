#!/bin/bash

collection_file=tests-cases/profile-tests/APIM_Environment.postman_environment.json
environment_file=tests-cases/profile-tests/Profile_Setup_Tests.postman_collection.json
ip=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq ".status.loadBalancer.ingress[0].ip")

newman run "$collection_file" \
  --environment "$environment_file" \
  --env-var "cluster_ip=$ip" \
  --insecure
