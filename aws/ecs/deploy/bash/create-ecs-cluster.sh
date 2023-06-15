#!/bin/bash
#Author: skondla@me.com
#Purpose: Setup ECS cluster and deploy a container web application

#enviroment variables

export ECR_REPOSITORY="webapp1-demo-shop"
export CLUSTER_NAME="webapp1-demo-shop"
export APP_DIR="../../../app1/"
export AWS_ACCOUNT_ID=`cat ~/.secrets | grep 'AWS_ACCOUNT_ID' | awk '{print $2}'`
export AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
#export IMAGE_TAG=$(git rev-parse --long HEAD | grep -v long)
export IMAGE_TAG=$(openssl rand -hex 32)


#Authenticate Docker to ECR
aws ecr get-login-password \
 --region ${AWS_REGION} | docker login --username AWS \
 --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

#IAM ROle Create Policy
cat <<EOF > create-iam-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:PutRolePolicy"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy \
 --policy-name create-iam-policy \
 --policy-document file://create-iam-policy.json

#Create IAM Policy for Elastic Container Services
# cat <<EOF > ecs-service-policy.json
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "ecsServicePolicy",
#             "Effect": "Allow",
#             "Action": [
#                 "ecs:CreateCluster",
#                 "ecs:DeregisterContainerInstance",
#                 "ecs:DiscoverPollEndpoint",
#                 "ecs:Poll",
#                 "ecs:RegisterContainerInstance",
#                 "ecs:StartTelemetrySession",
#                 "ecs:ListTasks",
#                 "ecs:ListContainerInstances",
#                 "ecs:DescribeContainerInstances",
#                 "ecs:DescribeTasks",
#                 "ecs:StartTask",
#                 "ecs:StopTask",
#                 "ecs:UpdateContainerInstancesState",
#                 "ecs:RegisterTaskDefinition",
#                 "ecs:Submit*",
#                 "ecr:BatchCheckLayerAvailability",
#                 "ecr:BatchGetImage",
#                 "ecr:GetDownloadUrlForLayer",
#                 "ecr:GetAuthorizationToken",
#                 "logs:CreateLogStream",
#                 "logs:PutLogEvents"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# EOF

# aws iam create-policy \
#  --policy-name ecs-service-policy \
#  --policy-document file://ecs-service-policy.json 

#Attach policy or manually attach via console
aws iam attach-user-policy \
 --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/ecs-service-policy --user-name skondla   

#ECSFullAccess Policy

aws iam create-policy \
 --policy-name ecs-full-access-policy \
 --policy-document file://ecsFullAccess.json

aws iam attach-user-policy \
 --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/ecs-full-access-policy --user-name skondla   

aws ecs create-cluster --cluster-name ${CLUSTER_NAME}

aws ecs list-container-instances --cluster ${CLUSTER_NAME}

#aws ecs describe-container-instances --cluster ${CLUSTER_NAME} --container-instances container_instance_ID

cat <<EOF > task_definition.json
{
    "family": "webapp1-demo-shop",
    "containerDefinitions": [
        {
            "name": "webapp1-demo-shop",
            "image": "webapp1-demo-shop",
            "cpu": 10,
            "memory": 500,
            "portMappings": [
                {
                    "containerPort": 25443,
                    "hostPort": 25443
                }
            ],
            "essential": true
        }
    ]
}
EOF

cat <<EOF > ecs-tasks-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
 --role-name ecsTaskExecutionRole \
 --assume-role-policy-document file://ecs-tasks-trust-policy.json

aws ecs register-task-definition --cli-input-json file://task_definition.json

aws ecs list-task-definitions

aws ecs describe-task-definition --task-definition webapp1-demo-shop --query taskDefinition > ${APP_DIR}/task_definition.json



#Create ECS Service

aws ecs create-service \
    --cluster webapp1-demo-shop \
    --service-name webapp1-demo-shop-service \
    --task-definition webapp1-demo-shop-2:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-0d526810628ef562f,subnet-062352c184a30488c,subnet-0cae3194b32ba0b38],securityGroups=[sg-0e4f9b540b09e1968],assignPublicIp=ENABLED}" \
    --tags key=key1,value=value1 key=key2,value=value2 key=key3,value=value3