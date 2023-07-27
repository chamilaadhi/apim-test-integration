#!/bin/bash

k8s_repo_dir=$1
reldir=`dirname $0`
echo "========= Running resource modifications ==================="
echo "= current dir :" $reldir
ls $reldir
## Remove one pub-devportal-tm node
rm -rf $k8s_repo_dir/advanced/am-pattern-2/templates/am/pub-devportal-tm/instance-2
## Remove init container from gateway deployment which checks for second pub-devportal-tm node
sed -i '/init-apim-2/,+2 d' $k8s_repo_dir/advanced/am-pattern-2/templates/am/gateway/wso2am-pattern-2-am-gateway-deployment.yaml

## copy all the resources to the k8s repo

echo "Copy content from $reldir to $k8s_repo_dir/advanced/am-pattern-2/"
cp -r $reldir/* $k8s_repo_dir/advanced/am-pattern-2/

