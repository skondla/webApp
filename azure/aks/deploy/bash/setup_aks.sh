#!/bin/bash
#Author: skondla.ai@gmail.com
#Purpose: setup azure container registry
#Date: 2022-06-23



#environmental variables
export AZ_SUBSCRIPTION_ID=`az account show --query id --output tsv`
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


# Set this variable to the name of your ACR. The name must be globally unique.
# Connected registry name must use only lowercase


az provider register --namespace 'microsoft.insights'

# Create an AKS cluster with ACR integration.

az aks create -n ${AZ_AKS_CLUSTER} -g ${AZ_RESOURCE_GROUP} --generate-ssh-keys --attach-acr ${AZ_CONTAINER_REGISTRY} \
 --node-count 1 \
 --node-vm-size Standard_B2s \
 --node-osdisk-size 30 \
 --nodepool-name webapps \
 --enable-addons monitoring \
 --enable-cluster-autoscaler \
 --min-count 1 \
 --max-count 3 \
 --node-count 1 \
 --enable-addons open-service-mesh

#Enable open service mesh
az aks enable-addons \
 --resource-group ${AZ_RESOURCE_GROUP} \
 --name ${AZ_AKS_CLUSTER} \
 --addons open-service-mesh
# Attach using acr-name
az aks update -n ${AZ_AKS_CLUSTER} -g ${AZ_RESOURCE_GROUP} --attach-acr ${AZ_CONTAINER_REGISTRY}

az aks get-credentials --resource-group ${AZ_RESOURCE_GROUP} --name ${AZ_AKS_CLUSTER}
#Output: Merged "webapps" as current context in /Users/skondla/.kube/config

# Attach using acr-resource-id
#az aks update -n ${AZ_AKS_CLUSTER} -g ${AZ_RESOURCE_GROUP} --attach-acr <acr-resource-id>


#Deploy Application

 envsubst < ${APP_MANIFEST_DIR}/webapp1.yaml | kubectl apply -f -
 envsubst < ${APP_MANIFEST_DIR}/Service.yaml | kubectl apply -f -
 envsubst < ${APP_MANIFEST_DIR}/Deployment.yaml | kubectl apply -f -


#Create Azure Credentials (later use for GitHub Actions)

az ad sp create-for-rbac \
 --name "ghActionWebApp" \
 --scope /subscriptions/${AZ_SUBSCRIPTION_ID}/resourceGroups/${AZ_RESOURCE_GROUP} \
 --role Contributor \
 --sdk-auth > ~/.private/azure_credentials.json
