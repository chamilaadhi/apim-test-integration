#!/bin/bash


echo "Hello world" $1 $2

echo pwd
pass=$1

echo "pass $pass" 

ls

ls scripts/kubernetes

#helm install wso2am scripts/kubernetes/advanced/am-pattern-2 --version 3.2.0-5 --namespace wso2 --dependency-update --create-namespace --set wso2.subscription.username=$1 --set wso2.subscription.password=$2 --set wso2.u2.username=$1 --set wso2.u2.password=$2



##############################################

namespace="wso2"

gcloud container clusters get-credentials cluster-1 --zone us-central1-c

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# delete existing deployment
helm delete wso2am -n $namespace
kubectl get pods -n $namespace -o name | xargs kubectl delete --force --grace-period=0 -n $namespace

helm repo add wso2 https://helm.wso2.com && helm repo update

helm install wso2am-3.2.0 wso2/am-pattern-1 --version 3.2.0-5 --namespace $namespace --create-namespace
