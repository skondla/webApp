#!/bin/bash
#Purpose: Delete your cluster
#Date: 2022-06-22

#When you no longer need the cluster, use the az group delete command to remove the resource group, the cluster, and all related resources

#environmental variables
export AZ_RESOURCE_GROUP=webapps
export AZ_REGION=eastus
export AZ_CONTAINER_REGISTRY=flaskwebapps
export IMAGE_TAG=$(openssl rand -hex 32)
export APP_DIR=../../../../app1/
export APP_NAME=webapp1

az group delete --name ${AZ_RESOURCE_GROUP} --yes --no-wait

