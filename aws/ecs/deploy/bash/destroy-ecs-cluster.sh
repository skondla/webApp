
#!/bin/bash
#Author: skondla@me.com
#Purpose: Destroy ECS cluster

#enviroment variables

export ECR_REPOSITORY="webapp1-demo-shop"
export ECS_CLUSTER_NAME="webapp1-demo-shop"
export ECS_SERVICE_NAME="webapp1-demo-shop-service"
export APP_DIR="../../../app1/"
export AWS_ACCOUNT_ID=`cat ~/.secrets | grep 'AWS_ACCOUNT_ID' | awk '{print $2}'`
export AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
#export IMAGE_TAG=$(git rev-parse --long HEAD | grep -v long)
export IMAGE_TAG=$(openssl rand -hex 32)


aws ecs list-task-definitions

aws ecs deregister-task-definition --task-definition curler:1
aws ecs delete-task-definitions --task-definition curltest:1

aws ecs delete-service --cluster ${ECS_CLUSTER_NAME} --service ${ECS_SERVICE_NAME} --force

aws ecs delete-cluster --cluster ${ECS_CLUSTER_NAME}