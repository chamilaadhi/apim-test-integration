#!/bin/bash


echo "Hello world" $1 $2

echo pwd
pass=$1

echo "pass $pass" 

ls

ls scripts/kubernetes

#helm install wso2am scripts/kubernetes/advanced/am-pattern-2 --version 3.2.0-5 --namespace wso2 --dependency-update --create-namespace --set wso2.subscription.username=$1 --set wso2.subscription.password=$2 --set wso2.u2.username=$1 --set wso2.u2.password=$2


# Reverse the variable content
reversedVariable=$(echo "$2" | rev)

# Print the reversed variable
echo "$reversedVariable"

##############################################

pattern=$1
username=$2
password=$3
analytics=$4

namespace="wso2"
project_name="wso2am"
startup_probe_delay="300"
readiness_probe_delay="300"

if [ -z "${WUM_USERNAME}" ]; then
    echo "WUM_USERNAME is empty"
else
    echo "WUM_USERNAME is not empty"
fi

if [ -z "${WUM_PASSWORD}" ]; then
    echo "WUM_PASSWORD is empty"
else
    echo "WUM_PASSWORD is not empty"
fi

if [ -z "${username}" ]; then
    echo "username is empty"
else
    echo "username is not empty"
fi

if [ -z "${password}" ]; then
    echo "password is empty"
else
    echo "password is not empty"
fi

gcloud container clusters get-credentials cluster-1 --zone us-central1-c

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# delete existing deployment
helm delete $project_name -n $namespace
kubectl get pods -n $namespace -o name | xargs kubectl delete --force --grace-period=0 -n $namespace

helm repo add wso2 https://helm.wso2.com && helm repo update

#helm install $project_name scripts/kubernetes/$pattern \
#        --version 3.2.0-5 --namespace $namespace --dependency-update --create-namespace \
#        --set wso2.subscription.username=$username --set wso2.subscription.password=$password \
#        --set wso2.u2.username=$username --set wso2.u2.password=$password
        
#helm install $project_name wso2/am-pattern-1 --version 3.2.0-5 --namespace $namespace --create-namespace --set wso2.analytics.dashboard.replicas=0 --set wso2.analytics.worker.resources.requests.memory=2G --set wso2.analytics.worker.resources.requests.cpu=1000m
#helm install $project_name wso2/am-single-node --version 4.2.0-1 --namespace $namespace --create-namespace

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
    --set wso2.deployment.dependencies.nfsServerProvisioner=false \
    --set wso2.deployment.dependencies.mysql=false \
    --set wso2.deployment.analytics.worker.enable=false \
    --set wso2.deployment.am.db.driver='org.h2.Driver' \
    --set wso2.deployment.am.db.type=h2 \
    --set wso2.deployment.am.db.apim.username=wso2carbon \
    --set wso2.deployment.am.db.apim.password=wso2carbon \
    --set wso2.deployment.am.db.apim.url='jdbc:h2:./repository/database/WSO2AM_DB;AUTO_SERVER=TRUE;DB_CLOSE_ON_EXIT=FALSE' \
    --set wso2.deployment.am.db.apim_shared.username=wso2carbon \
    --set wso2.deployment.am.db.apim_shared.password=wso2carbon \
    --set wso2.deployment.am.db.apim_shared.url='jdbc:h2:./repository/database/WSO2SHARED_DB;DB_CLOSE_ON_EXIT=FALSE'
    


kubectl get ing -n $namespace
    

