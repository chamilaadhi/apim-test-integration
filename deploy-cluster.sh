#!/bin/bash

##############################################

pattern=$1
username=$2
password=$3
analytics=$4

namespace="wso2"
project_name="wso2am"
startup_probe_delay="300"
readiness_probe_delay="300"

gcloud container clusters get-credentials cluster-1 --zone us-central1-c

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# delete existing deployment
helm delete $project_name -n $namespace
kubectl get pods -n $namespace -o name | xargs kubectl delete --force --grace-period=0 -n $namespace

helm repo add wso2 https://helm.wso2.com && helm repo update

helm install $project_name \
    scripts/kubernetes/$pattern \
    --version 3.2.0-5 \
    --namespace $namespace \
    --dependency-update \
    --create-namespace \
    --set wso2.subscription.username=$username \
    --set wso2.subscription.password=$password \
    --set wso2.u2.username=$username \
    --set wso2.u2.password=$password \
    --set wso2.deployment.am.gateway.startupProbe.initialDelaySeconds=$startup_probe_delay \
    --set wso2.deployment.am.gateway.readinessProbe.initialDelaySeconds=$readiness_probe_delay \
    --set wso2.deployment.am.km.startupProbe.initialDelaySeconds=$startup_probe_delay \
    --set wso2.deployment.am.km.readinessProbe.initialDelaySeconds=$readiness_probe_delay \
    --set wso2.deployment.am.pubDevPortalTM.startupProbe.initialDelaySeconds=$startup_probe_delay \
    --set wso2.deployment.am.pubDevPortalTM.readinessProbe.initialDelaySeconds=$readiness_probe_delay \
    --set wso2.deployment.dependencies.nfsServerProvisioner=true \
    --set wso2.deployment.dependencies.mysql=true \
    --set wso2.deployment.analytics.worker.enable=true 
    


kubectl get ing -n $namespace
    

