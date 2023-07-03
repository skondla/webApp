#!/bin/bash
#Author: skondla@me.com
#Purpose: Install and Setup EKS cluster and deploy a container web application

#enviroment variables
#source ./webapp_eks_env.sh

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
export SUBNET_FILE=~/Downloads/subnets.list
export CF_STACK_NAME=${EKS_CLUSTER_NAME}

aws sts get-caller-identity
#Step 1.1: Create your Amazon EKS cluster
 
aws cloudformation create-stack \
 --region ${AWS_REGION} \
 --stack-name ${CF_STACK_NAME} \
 --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml

echo "Sleeping for 3 minutes to allow the stack to be created..."

sleep 180


cat >eks-cluster-role-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role --role-name myAmazonEKSClusterRole --assume-role-policy-document file://"eks-cluster-role-trust-policy.json"
#aws iam attach-role-policy --role-name myAmazonEKSClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name myAmazonEKSClusterRole

cat >eks_cluster_role_policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "eks.amazonaws.com"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name fullAccessEKSClusterRole --assume-role-policy-document file://"eks_cluster_role_policy.json"
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name fullAccessEKSClusterRole


cat >eks_admin.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "eks:*",
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
aws iam create-role --role-name eks_admin --assume-role-policy-document file://"eks_admin.json"
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name eks_admin

#Install eksctl (macOS) : Refer https://eksctl.io/introduction/#prerequisite

brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
. <(eksctl completion bash)


#FULL ACCESS TO EKS*

cat >eks_cluster_role_policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "eks.amazonaws.com"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name fullAccessEKSClusterRole --assume-role-policy-document file://eks_cluster_role_policy.json
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name fullAccessEKSClusterRole

cat >node-role-trust-relationship.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name AmazonEKSNodeRole \
  --assume-role-policy-document file://"node-role-trust-relationship.json"

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  --role-name AmazonEKSNodeRole

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --role-name AmazonEKSNodeRole

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
  --role-name AmazonEKSNodeRole
#Get subnets from stack and inject them to eksctl create cluster command

aws cloudformation describe-stacks --stack-name ${CF_STACK_NAME}-stack --query "Stacks[0].Outputs[0].OutputValue" --output text > ~/Downloads/cf_stack.output
aws cloudformation describe-stacks --stack-name ${CF_STACK_NAME}-stack --query "Stacks[0].Outputs[1].OutputValue" --output text >> ~/Downloads/cf_stack.output 
aws cloudformation describe-stacks --stack-name ${CF_STACK_NAME}-stack --query "Stacks[0].Outputs[2].OutputValue" --output text >> ~/Downloads/cf_stack.output
echo `cat ~/Downloads/cf_stack.output  | grep "subnet"` | { while read -d, i; do echo "$i"; done; echo "$i"; } > ~/Downloads/subnets.list

export SUBNET_FILE=~/Downloads/subnets.list
export EKS_PUBLIC_SUBNET1=`awk 'NR==1' ${SUBNET_FILE}`
export EKS_PUBLIC_SUBNET2=`awk 'NR==2' ${SUBNET_FILE}`
export EKS_PRIVATE_SUBNET1=`awk 'NR==3' ${SUBNET_FILE}`
export EKS_PRIVATE_SUBNET2=`awk 'NR==4' ${SUBNET_FILE}`


eksctl create cluster \
 --name ${EKS_CLUSTER_NAME} \
 --version 1.27 \
 --region ${AWS_REGION} \
 --nodegroup-name standard-workers \
 --node-type t3.micro \
 --nodes 4 \
 --nodes-min 3 \
 --nodes-max 6 \
 --managed \
 --ssh-public-key ~/.ssh/id_rsa.pub \
 --vpc-private-subnets=${EKS_PRIVATE_SUBNET1},${EKS_PRIVATE_SUBNET2} \
 --vpc-public-subnets=${EKS_PUBLIC_SUBNET1},${EKS_PUBLIC_SUBNET2} 

aws eks update-kubeconfig \
 --region ${AWS_REGION} \
 --name ${EKS_CLUSTER_NAME}

kubectl get svc

#Deploy Application

 envsubst < ${APP_MANIFEST_DIR}/webapp1.yaml | kubectl apply -f -
 envsubst < ${APP_MANIFEST_DIR}/Service.yaml | kubectl apply -f -
 envsubst < ${APP_MANIFEST_DIR}/Deployment.yaml | kubectl apply -f -


 #Enable logging on EKS cluster

 eksctl utils update-cluster-logging \
  --enable-types="all" \
  --region=${AWS_REGION} \
  --cluster=${EKS_CLUSTER_NAME} \
  --approve

#2023-06-29 17:33:55 [ℹ]  will update CloudWatch logging for cluster "webapps-demo" in "us-east-1" 
#(enable types: api, audit, authenticator, controllerManager, scheduler & no types to disable)
