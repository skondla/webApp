#!/bin/bash
source ~/.secrets

#environmental variables
export AZ_RESOURCE_GROUP=webapps
export AZ_REGION=eastus
export AZ_CONTAINER_REGISTRY=flaskwebapps
export APP_NAME=webapp1
export AZ_AKS_CLUSTER=webapps
export AKS_APP_NAME="webapp1"
export AKS_SERVICE="webapp1"
export AKS_SERVICE_ACCOUNT="webapp1-sa"
export AKS_NAMESPACE="webapp"
export IMAGE_NAME=`cat /Users/skondla/Downloads/webapp_acr_image.txt|awk '{print $1}'`
export APP_MANIFEST_DIR="../manifest/webapp1"


envsubst < secret_pg.yaml | kubectl apply -f -
envsubst < csi_storage_class_pg.yaml | kubectl apply -f -
envsubst < csi_pvc_pg.yaml | kubectl apply -f -
#envsubst < pv_pg.yaml | kubectl apply -f -
#envsubst < pvc_pg.yaml | kubectl apply -f -
envsubst < deployment_pg.yaml | kubectl apply -f -
envsubst < service_pg.yaml | kubectl apply -f -
