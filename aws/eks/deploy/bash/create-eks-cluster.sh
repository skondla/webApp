#!/bin/bash
#Author: skondla@me.com
#Purpose: Install and Setup EKS cluster and deploy a container web application


#Dependencies:
  #Run this script after ../../../ecr/deploy/bash/setup-ecr.sh
#enviroment variables

source ./webapp_eks_env.sh
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

#Step 2: Configure your computer to communicate with your cluster
aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}

kubectl get svc

#Step 3: Launch and Configure Amazon EKS Worker Nodes

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

#Step 3.2: Launch the Amazon EKS worker nodes

#Step 3.1: Create an Amazon EKS node group

# eksctl create nodegroup \
#   --cluster ${EKS_CLUSTER_NAME} \
#   --region ${AWS_REGION} \
#   --name ${EKS_CLUSTER_NAME}-mng \
#   --node-ami-family Ubuntu2004 \
#   --node-type t3.micro \
#   --nodes 3 \
#   --nodes-min 2 \
#   --nodes-max 4 \
#   --ssh-access \
#   --ssh-public-key ~/.ssh/id_rsa.pub 

#Step 3.3: Verify that your worker nodes registered with your cluster
#Step 3.4: Launch a sample application
#Step 3.5: Clean up


#Provision Cluster
#eksctl create cluster --config-file ./cr_eks.yaml

#Deploy Application

 envsubst < ${APP_MANIFEST_DIR}/webapp1.yaml | kubectl apply -f -
 envsubst < ${APP_MANIFEST_DIR}/Service.yaml | kubectl apply -f -
 envsubst < ${APP_MANIFEST_DIR}/Deployment.yaml | kubectl apply -f -