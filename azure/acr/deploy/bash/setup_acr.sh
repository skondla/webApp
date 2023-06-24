#!/bin/bash
#Author: skondla.ai@gmail.com
#Purpose: setup azure container registry
#Date: 2022-06-22

#environmental variables
export AZ_RESOURCE_GROUP=webapps
export AZ_REGION=eastus
export AZ_CONTAINER_REGISTRY=flaskwebapps
export IMAGE_TAG=$(openssl rand -hex 32)
export APP_DIR=../../../../app1/
export APP_NAME=webapp1
export IMAGE_NAME=${APP_NAME}.${AZ_CONTAINER_REGISTRY}.azurecr.io/${APP_NAME}:${IMAGE_TAG}

az group create --location ${AZ_REGION} --resource-group ${AZ_RESOURCE_GROUP}
az acr create --resource-group ${AZ_RESOURCE_GROUP} --name ${AZ_CONTAINER_REGISTRY} --sku Basic
az acr login -n ${AZ_CONTAINER_REGISTRY} --expose-token

docker build -t ${APP_NAME} ${APP_DIR}
docker tag ${IMAGE_NAME}
az acr login --name ${AZ_CONTAINER_REGISTRY}
docker push ${IMAGE_NAME}
echo "${IMAGE_NAME}" > ~/Downloads/webapp_acr_image.txt
#docker push myimages08102020.azurecr.io/samples/dbwebapi
