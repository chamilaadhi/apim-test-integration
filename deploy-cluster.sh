#!/bin/bash


echo "Hello world" $1 $2

echo pwd
pass=$1

echo "pass $pass" 

ls

ls scripts/kubernetes

helm install wso2am scripts/kubernetes/advanced/am-pattern-2 --version 3.2.0-5 --namespace wso2 --dependency-update --create-namespace --set wso2.subscription.username=$1 --set wso2.subscription.password=$2 --set wso2.u2.username=$1 --set wso2.u2.password=$2
