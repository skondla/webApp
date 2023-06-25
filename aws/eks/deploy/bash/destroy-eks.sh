#!/bin/bash
#Author: skondla@me.com
#Purpose: Destroy a new instance of EKS cluster 
#enviroment variables
export EKS_CLUSTER_NAME="webapps-demo"
#export APP_DIR="../../../app1/"
export AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
#export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
eksctl delete cluster --name=${EKS_CLUSTER_NAME} --region=${AWS_REGION}
