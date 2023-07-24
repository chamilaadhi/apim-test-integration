workingdir=$(pwd)
reldir=`dirname $0`
cd $reldir

#rev1=$(echo "${WUM_USER}" | rev)
#rev2=$(echo "${product_name}" | rev)
#rev3=$(echo "$3" | rev)
#echo "===========rev1 =====" $rev1
#echo "===========rev2 =====" $rev2
#echo "===========rev3 =====" $rev3


echo " _+_ " ${product_name}
echo " _+_ " ${WUM_USER}


source ./utils.sh


isEmpty "${EKS_CLUSTER_NAME}";
flag=$?
if [ $flag = 1 ];
    then echo "EKS_CLUSTER_NAME environment variable is empty."; exit 1
fi;

isEmpty "${EKS_CLUSTER_REGION}";
flag=$?
if [ $flag = 1 ];
    then echo "EKS_CLUSTER_REGION environment variable is empty."; exit 1
fi;

isEmpty "${RDS_STACK_NAME}";
flag=$?
if [ $flag = 1 ];
    then echo "RDS_STACK_NAME environment variable is empty."; exit 1
fi;

isEmpty "${path_to_helm_folder}";
flag=$?
if [ $flag = 1 ];
    then echo "Path to helm folder is empty."; exit 1
fi;

isEmpty "${product_version}";
flag=$?
if [ $flag = 1 ];
    then echo "Product version is empty."; exit 1
fi;

isEmpty "${db_engine}";
flag=$?
if [ $flag = 1 ];
    then echo "DB engine value is empty."; exit 1
fi;

dbDriver=""
driverUrl=""
dbType=""
dbUserNameAPIM="wso2carbon"
dbPasswordAPIM="wso2carbon"
dbUserNameAPIMShared="wso2carbon"
dbPasswordAPIMShared="wso2carbon"
dbAPIMUrl=""
dbAPIMDSharedUrl=""
if [ "${db_engine}" = "postgres" ];
    then 
        dbDriver="org.postgresql.Driver"
        driverUrl="https://repo1.maven.org/maven2/org/postgresql/postgresql/42.3.6/postgresql-42.3.6.jar"
        dbType="postgre"
        dbEngine="postgres"
elif [ "${db_engine}" = "mysql" ];
    then 
        dbDriver="com.mysql.cj.jdbc.Driver"
        driverUrl="https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.29/mysql-connector-java-8.0.29.jar"
        dbType="mysql"
        dbEngine="mysql"
elif [ "${db_engine}" = "mssql" ];
    then 
        dbDriver="com.microsoft.sqlserver.jdbc.SQLServerDriver"
        driverUrl="https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/10.2.1.jre11/mssql-jdbc-10.2.1.jre11.jar"
        dbType="mssql"
        dbEngine="sqlserver-ex"
elif [ "${db_engine}" = "oracle" ];
    then 
        ="oracle.jdbc.OracleDriver"
        driverUrl="https://download.oracle.com/otn-pub/otn_software/jdbc/215/ojdbc11.jar"
        dbType="oracle"
        dbEngine="oracle-se2"
        dbUserNameAPIM="WSO2AM_DB"
        dbPasswordAPIM="wso2carbon"
        dbUserNameAPIMShared="WSO2AM_SHARED_DB"
        dbPasswordAPIMShared="wso2carbon"
else
    echo "The specified DB engine not supported.";
    exit 1;
fi;


# Download DB scripts from S3 bucket.
mkdir "${db_engine}"
#aws s3 cp "s3://test-grid-apim/profile-automation/apim/${product_version}/${db_engine}/" "./${db_engine}/" --recursive || { echo 'Failed to download DB scripts.';  exit 1; }
aws s3 cp "s3://test-grid-apim/profile-automation/apim/3.2.0/${db_engine}/" "./${db_engine}/" --recursive || { echo 'Failed to download DB scripts.';  exit 1; }

# Update kube config file.
aws eks update-kubeconfig --region ${EKS_CLUSTER_REGION} --name ${EKS_CLUSTER_NAME} || { echo 'Failed to update cluster kube config.';  exit 1; }

# Scale node group with one EC2 instance.
eksctl scale nodegroup --region ${EKS_CLUSTER_REGION} --cluster ${EKS_CLUSTER_NAME} --name ng-1 --nodes=1 || { echo 'Failed to scale the node group.';  exit 1; }

# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/aws/deploy.yaml || { echo "failed to install nginx ingress controller." ; exit 1 ; }

# Delete Nginx admission if it exists.
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission || echo "WARNING : Failed to delete nginx admission."

# Create fargate profile
eksctl create fargateprofile --cluster "${EKS_CLUSTER_NAME}" --name "${product_name}-fargate-profile" --namespace "${kubernetes_namespace}" --region ${EKS_CLUSTER_REGION} || { echo "Failed to create fargate profile." ; exit 1 ; }

# Extract DB port and DB host name detail.
dbPort=$(aws cloudformation describe-stacks --stack-name "${RDS_STACK_NAME}" --region "${EKS_CLUSTER_REGION}" --query 'Stacks[?StackName==`'$RDS_STACK_NAME'`][].Outputs[?OutputKey==`TestgridDBJDBCPort`].OutputValue' --output text | xargs)
dbHost=$(aws cloudformation describe-stacks --stack-name "${RDS_STACK_NAME}" --region "${EKS_CLUSTER_REGION}" --query 'Stacks[?StackName==`'$RDS_STACK_NAME'`][].Outputs[?OutputKey==`TestgridDBJDBCConnectionString`].OutputValue' --output text | xargs)
echo "Db details DB port : $dbPort, DB host : $dbHost"

if [ "${db_engine}" = "postgres" ];
    then 
        dbAPIMUrl="jdbc:postgresql://$dbHost:$dbPort/WSO2AM_DB?useSSL=false&amp;autoReconnect=true&amp;requireSSL=false&amp;verifyServerCertificate=false"
        dbAPIMSharedUrl="jdbc:postgresql://$dbHost:$dbPort/WSO2AM_SHARED_DB?useSSL=false&amp;autoReconnect=true&amp;requireSSL=false&amp;verifyServerCertificate=false"
elif [ "${db_engine}" = "mysql" ];
    then 
        dbAPIMUrl="jdbc:mysql://$dbHost:$dbPort/WSO2AM_DB?useSSL=false&amp;autoReconnect=true&amp;requireSSL=false&amp;verifyServerCertificate=false&amp;allowPublicKeyRetrieval=true"
        dbAPIMSharedUrl="jdbc:mysql://$dbHost:$dbPort/WSO2AM_SHARED_DB?useSSL=false&amp;autoReconnect=true&amp;requireSSL=false&amp;verifyServerCertificate=false&amp;allowPublicKeyRetrieval=true"
elif [ "${db_engine}" = "mssql" ];
    then 
        dbAPIMUrl="jdbc:sqlserver://$dbHost:$dbPort;databaseName=WSO2AM_DB;SendStringParametersAsUnicode=false;encrypt=false"
        dbAPIMSharedUrl="jdbc:sqlserver://$dbHost:$dbPort;databaseName=WSO2AM_SHARED_DB;;SendStringParametersAsUnicode=false;encrypt=false"
elif [ "${db_engine}" = "oracle" ];
    then 
        dbAPIMUrl="jdbc:oracle:thin:@$dbHost:$dbPort:ORCL"
        dbAPIMSharedUrl="jdbc:oracle:thin:@$dbHost:$dbPort:ORCL"
else
    echo "The specified DB engine not supported.";
    exit 1;
fi;


# Validate DB Port.
isEmpty "${dbPort}";
flag=$?
if [ $flag = 1 ];
    then 
        echo "Extracted db port value is empty."; exit 1
fi;

# Validate DB host name.
isEmpty "${dbHost}";
flag=$?
if [ $flag = 1 ];
    then 
        echo "Extracted DB host is empty."; exit 1
fi;

# Provision rds db
./provision_db_apim.sh "${db_engine}" "${DB_PASSWORD}" "$dbHost" "${DB_USERNAME}" "$dbPort" || exit 1

# Wait for nginx to come alive.
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=480s ||  { echo 'Nginx service is not ready within the expected time limit.';  exit 1; }

# Install APIM using helm.
helm repo add wso2 https://helm.wso2.com && helm repo update ||  { echo 'Error while adding WSO2 helm repository to helm.';  exit 1; }
helm dependency build "kubernetes-apim/${path_to_helm_folder}" ||  { echo 'Error while building helm folder : kubernetes-apim/${path_to_helm_folder}.';  exit 1; }
#helm install apim "kubernetes-apim/${path_to_helm_folder}" \
#    --set wso2.deployment.am.cp.db.hostname="$dbHost" \
#    --set wso2.deployment.am.cp.db.port="$dbPort" \
#    --set wso2.deployment.am.cp.db.type="$dbType" \
#    --set wso2.deployment.am.cp.db.driver="$dbDriver" \
#    --set wso2.deployment.am.cp.db.driver_url="$driverUrl" \
#    --set wso2.deployment.am.cp.db.apim.username="$dbUserNameAPIM" \
#    --set wso2.deployment.am.cp.db.apim_shared.username="$dbUserNameAPIMShared" \
#    --set wso2.deployment.am.cp.db.apim.password="$dbPasswordAPIM" \
#    --set wso2.deployment.am.cp.db.apim_shared.password="$dbPasswordAPIMShared" \
#    --set wso2.deployment.am.cp.db.apim.url="$dbAPIMUrl" \
#    --set wso2.deployment.am.cp.db.apim_shared.url="$dbAPIMSharedUrl" \
#    --set wso2.deployment.dependencies.cluster_mysql=false \
#    --set wso2.deployment.am.trafficmanager.livenessProbe.initialDelaySeconds=300 \
#    --set wso2.deployment.am.trafficmanager.readinessProbe.initialDelaySeconds=300 \
#    --set wso2.deployment.am.cp.startupProbe.initialDelaySeconds=200 \
#    --set wso2.deployment.am.cp.readinessProbe.initialDelaySeconds=200 \
#    --set wso2.deployment.am.startupProbe.initialDelaySeconds=200 \
#    --set wso2.deployment.am.startupProbe.periodSeconds=10 \
#    --set wso2.deployment.am.readinessProbe.initialDelaySeconds=200 \
#    --set wso2.deployment.dependencies.nfsServerProvisioner=false \
#    --set wso2.subscription.username="$wum_usr" \
#    --set wso2.subscription.password="$wum_pwd" \
#    --set wso2.deployment.mi.replicas=0 \
#    --namespace "${kubernetes_namespace}" --create-namespace \
#    ||  { echo 'Error while instaling APIM to cluster.';  exit 1; }

username=${WUM_USER}
password=${WUM_PWD}
if [ -z "${username}" ]; then
    echo "====== username is empty ========"
else
    echo "====== username is not empty ===="
fi

if [ -z "${password}" ]; then
    echo "======= password is empty ======="
else
    echo "====== password is not empty ===="
fi

echo "Installing Helm chart - ns ${kubernetes_namespace}  "
#helm install apim \
#    "kubernetes-apim/${path_to_helm_folder}" \
#    --version 3.2.0-5 \
#    --namespace "${kubernetes_namespace}" \
#    --create-namespace \
#    --set wso2.subscription.username=${WUM_USER} \
#    --set wso2.subscription.password=${WUM_PWD} \
#    --set wso2.u2.username=${WUM_USER} \
#    --set wso2.u2.password=${WUM_PWD} \
#    --set wso2.deployment.am.gateway.startupProbe.initialDelaySeconds=300 \
#    --set wso2.deployment.am.gateway.readinessProbe.initialDelaySeconds=300 \
#    --set wso2.deployment.am.km.startupProbe.initialDelaySeconds=300 \
#    --set wso2.deployment.am.km.readinessProbe.initialDelaySeconds=300 \
#    --set wso2.deployment.am.pubDevPortalTM.startupProbe.initialDelaySeconds=300 \
#    --set wso2.deployment.am.pubDevPortalTM.readinessProbe.initialDelaySeconds=300 \
#    --set wso2.deployment.dependencies.nfsServerProvisioner=false \
#    --set wso2.deployment.dependencies.mysql=false \
#    --set wso2.deployment.analytics.worker.enable=true \
#    --set wso2.deployment.am.db.driver="$dbDriver" \
#    --set wso2.deployment.am.db.type="$dbType" \
#    --set wso2.deployment.am.db.apim.username=wso2carbon \
#    --set wso2.deployment.am.db.apim.password=wso2carbon \
#    --set wso2.deployment.am.db.apim.url="$dbAPIMUrl" \
#    --set wso2.deployment.am.db.apim_shared.username=wso2carbon \
#    --set wso2.deployment.am.db.apim_shared.password=wso2carbon \
#    --set wso2.deployment.am.db.apim_shared.url="$dbAPIMSharedUrl" \
#    ||  { echo 'Error while installing APIM to cluster.';  exit 1; }

helm install apim "kubernetes-apim/${path_to_helm_folder}" --version 3.2.0-5 --namespace "${kubernetes_namespace}" --dependency-update --create-namespace \
    --set wso2.subscription.username=${WUM_USER} \
    --set wso2.subscription.password=${WUM_PWD} \
    --set wso2.deployment.dependencies.nfsServerProvisioner=false \
    --set wso2.deployment.dependencies.cluster_mysql=false \
    --set wso2.deployment.am.gateway.replicas=1 \
    --set wso2.deployment.am.km.replicas=1 \
    --set wso2.deployment.analytics.dashboard.replicas=0 \
    --set wso2.deployment.analytics.worker.replicas=1 \
    --set wso2.deployment.am.db.hostname="$dbHost" \
    --set wso2.deployment.am.db.port="$dbPort" \
    --set wso2.deployment.am.db.type="$dbType" \
    --set wso2.deployment.am.db.driver="$dbDriver" \
    --set wso2.deployment.am.db.driver_url="$driverUrl" \
    --set wso2.deployment.am.db.apim.username="$dbUserNameAPIM" \
    --set wso2.deployment.am.db.apim.password="$dbPasswordAPIM" \
    --set wso2.deployment.am.db.apim.url="$dbAPIMUrl" \
    --set wso2.deployment.am.db.apim_shared.username="$dbUserNameAPIMShared" \
    --set wso2.deployment.am.db.apim_shared.password="$dbPasswordAPIMShared" \
    --set wso2.deployment.am.db.apim_shared.url="$dbAPIMSharedUrl" \
    --set wso2.deployment.analytics.db.hostname="$dbHost" \
    --set wso2.deployment.analytics.db.port="$dbPort" \
    --set wso2.deployment.analytics.db.driver="$dbDriver" \
    --set wso2.deployment.analytics.db.driver_url="$driverUrl" \
    --set wso2.deployment.analytics.db.connection_test_query="SELECT 1" \
    --set wso2.deployment.analytics.db.permission_db.username="$dbUserNameAPIM" \
    --set wso2.deployment.analytics.db.permission_db.password="$dbPasswordAPIM" \
    --set wso2.deployment.analytics.db.permission_db.url="jdbc:mysql://$dbHost:$dbPort/WSO2AM_PERMISSIONS_DB?useSSL=false" \
    --set wso2.deployment.analytics.db.analytics_db.username="$dbUserNameAPIM" \
    --set wso2.deployment.analytics.db.analytics_db.password="$dbPasswordAPIM" \
    --set wso2.deployment.analytics.db.analytics_db.url="jdbc:mysql://$dbHost:$dbPort/WSO2AM_STATS_DB?useSSL=false" \
    --set wso2.deployment.analytics.db.cluster_db.username="$dbUserNameAPIM" \
    --set wso2.deployment.analytics.db.cluster_db.password="$dbPasswordAPIM" \
    --set wso2.deployment.analytics.db.cluster_db.url="jdbc:mysql://$dbHost:$dbPort/WSO2_CLUSTER_DB?useSSL=false" \
    --set wso2.deployment.analytics.db.persistence_db.username="$dbUserNameAPIM" \
    --set wso2.deployment.analytics.db.persistence_db.password="$dbPasswordAPIM" \
    --set wso2.deployment.analytics.db.persistence_db.url="jdbc:mysql://$dbHost:$dbPort/WSO2_PERSISTENCE_DB?useSSL=false" \
    --set wso2.deployment.am.gateway.readinessProbe.initialDelaySeconds=180 \
    --set wso2.deployment.am.gateway.livenessProbe.initialDelaySeconds=180 \
    --set wso2.deployment.am.km.readinessProbe.initialDelaySeconds=180 \
    --set wso2.deployment.am.km.livenessProbe.initialDelaySeconds=180 \
    --set wso2.deployment.analytics.worker.readinessProbe.initialDelaySeconds=60 \
    --set wso2.deployment.analytics.worker.livenessProbe.initialDelaySeconds=60 \
    ||  { echo 'Error while installing APIM to cluster.';  exit 1; }

cd "$workingdir"

