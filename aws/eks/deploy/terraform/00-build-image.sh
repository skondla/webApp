#!/bin/bash
#Author: skondla@me.com
#Purpose: Create a Elastic Container Registry, Docker Build and instance of ECS cluster and deploy a container web application


export AWS_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`
export AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export ECR_REPOSITORY="webapp1-demo-shop"
export APP_DIR="../../../../app1/"

aws ecr get-login-password --region {$AWS_REGION} | docker login --username AWS --password-stdin {$AWS_ACCOUNT_ID}.dkr.ecr.{$AWS_REGION}.amazonaws.com
#docker build -t webapp1-demo-shop .
docker build -t webapp1-demo-shop $APP_DIR
docker tag webapp1-demo-shop:latest {$AWS_ACCOUNT_ID}.dkr.ecr.{$AWS_REGION}.amazonaws.com/webapp1-demo-shop:latest
docker push {$AWS_ACCOUNT_ID}.dkr.ecr.{$AWS_REGION}.amazonaws.com/webapp1-demo-shop:latest
