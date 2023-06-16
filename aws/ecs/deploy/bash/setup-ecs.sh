#!/bin/bash
#Author: skondla@me.com
#Purpose: Create a Elastic Container Registry, Docker Build and instance of ECS cluster and deploy a container web application

#enviroment variables

export ECR_REPOSITORY="webapp1-demo-shop"
export APP_DIR="../../../app1/"
export AWS_ACCOUNT_ID=`cat ~/.secrets | grep 'AWS_ACCOUNT_ID' | awk '{print $2}'`
export AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
#export IMAGE_TAG=$(git rev-parse --long HEAD | grep -v long)
export IMAGE_TAG=$(openssl rand -hex 32)

#Create ECS cluster
# aws cloudformation create-stack \
#  --stack-name webapp1-demo-shop \
#  --template-body file://${PWD}/ecs.yaml \
#  --capabilities CAPABILITY_NAMED_IAM \
#  --parameters ParameterKey=DockerAuth,ParameterValue={}



#Create ECS cluster
aws cloudformation create-stack \
 --stack-name webapp1-demo-shop \
 --template-body file://${PWD}/ecs.yaml \
 --capabilities CAPABILITY_NAMED_IAM \
 --parameters ParameterKey=DockerAuth,ParameterValue={}