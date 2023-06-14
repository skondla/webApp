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
export IMAGE_TAG=`cat ~/Downloads/ecr_image.txt  | grep imageTag | awk '{print $2}'`


aws ecr batch-delete-image \
 --repository-name ${ECR_REPOSITORY} \
 --image-ids imageTag=${IMAGE_TAG} \
 --region ${AWS_REGION}

aws ecr delete-repository \
 --repository-name ${ECR_REPOSITORY} \
 --force \
 --region ${AWS_REGION}
