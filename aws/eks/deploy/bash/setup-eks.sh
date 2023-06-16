
#!/bin/bash
#Author: skondla@me.com
#Purpose: Create a new instance of EKS cluster and deploy a container web application

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

#Create EKS cluster
eksctl create cluster \
--name webapp1-demo-shop \
--version 1.17 \
--region ${AWS_REGION} \
--nodegroup-name standard-workers \
--node-type t3.micro \
--nodes 3 \
--nodes-min 1 \
--nodes-max 4 \
--managed