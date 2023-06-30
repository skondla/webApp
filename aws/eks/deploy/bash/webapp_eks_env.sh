#!/bin/bash

export ECR_REPOSITORY="webapp1-demo-shop"
export EKS_CLUSTER_NAME="webapps-demo"
export APP_DIR="../../../app1/"
export AWS_ACCOUNT_ID=`cat ~/.secrets | grep 'AWS_ACCOUNT_ID' | awk '{print $2}'`
export AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
#export IMAGE_TAG=$(git rev-parse --long HEAD | grep -v long)
export IMAGE_TAG=$(openssl rand -hex 32)
export ECR_REPOSITORY_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
export EKS_APP_NAME="webapp1-demo-shop"
export EKS_SERVICE="webapp1"
export EKS_SERVICE_ACCOUNT="webapp1-sa"
export EKS_NAMESPACE="webapp"
export IMAGE_NAME=`cat ~/Downloads/webapp_ecr_image.txt | grep imageName|awk '{print $2}'`
export APP_MANIFEST_DIR="../manifest/webapp1"
# export EKS_PRIVATE_SUBNET1="subnet-02b74b454744a8394"
# export EKS_PRIVATE_SUBNET2="subnet-0adda7ae20f26f1d5"
# export EKS_PUBLIC_SUBNET1="subnet-0635302237d16e28a"
# export EKS_PUBLIC_SUBNET2="subnet-0be1b29a1c6677f00"

export SUBNET_FILE=~/Downloads/subnets.list
export EKS_PUBLIC_SUBNET1=`awk 'NR==1' ${SUBNET_FILE}`
export EKS_PUBLIC_SUBNET2=`awk 'NR==2' ${SUBNET_FILE}`
export EKS_PRIVATE_SUBNET1=`awk 'NR==3' ${SUBNET_FILE}`
export EKS_PRIVATE_SUBNET2=`awk 'NR==4' ${SUBNET_FILE}`
