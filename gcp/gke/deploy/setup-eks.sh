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

#Authenticate Docker to ECR
aws ecr get-login-password \
 --region ${AWS_REGION} | docker login --username AWS \
 --password-stdin aws_account_id.dkr.ecr.region.amazonaws.com

#Cretate ECR repo
aws ecr create-repository \
 --repository-name ${ECR_REPOSITORY} \
 --region ${AWS_REGION} \
 --image-scanning-configuration scanOnPush=true \
 --image-tag-mutability MUTABLE

#Push image to ECR



# Build and push the docker image
imagename=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

docker build --tag \
  "$GKE_REGION-docker.pkg.dev/$GKE_PROJECT/$GKE_PROJECT/$GKE_APP_NAME:$GITHUB_SHA" \
  ${APP_DIR}/
gcloud auth configure-docker $GKE_REGION-docker.pkg.dev --quiet
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://$GKE_REGION-docker.pkg.dev
docker push "$GKE_REGION-docker.pkg.dev/$GKE_PROJECT/$GKE_PROJECT/$GKE_APP_NAME:$GITHUB_SHA"


