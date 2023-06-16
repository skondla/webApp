#!/bin/bash
#Author: skondla@me.com
#Purpose: Install and Setup EKS cluster and deploy a container web application

#enviroment variables

export ECR_REPOSITORY="webapp1-demo-shop"
export EKS_CLUSTER_NAME="webapp1-demo-shop"
export APP_DIR="../../../app1/"
export AWS_ACCOUNT_ID=`cat ~/.secrets | grep 'AWS_ACCOUNT_ID' | awk '{print $2}'`
export AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
#export IMAGE_TAG=$(git rev-parse --long HEAD | grep -v long)
export IMAGE_TAG=$(openssl rand -hex 32)
export CF_STACK_NAME=${EKS_CLUSTER_NAME}-stack


#Pre-requisites
#reference: https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html

aws sts get-caller-identity
#Step 1.1: Create your Amazon EKS cluster
 
aws cloudformation create-stack \
  --region ${AWS_REGION} \
  --stack-name ${CF_STACK_NAME} \
  --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml


#Step 1.2: Create an Amazon VPC with public and private subnets that meets Amazon EKS

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

#Step 1.3: Create the Amazon EKS cluster role
aws iam create-role --role-name webAppEKSClusterRole --assume-role-policy-document file://"eks-cluster-role-trust-policy.json"

#Step 1.4: Attach the Amazon EKS cluster policy to the role
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name webAppEKSClusterRole

#head over to AWS console to create EKS cluster (This needs to be scripted)

# Open the Amazon EKS console at https://console.aws.amazon.com/eks/home#/clusters.
# Make sure that the AWS Region shown in the upper right of your console is the AWS Region that you want to create your cluster in. If it's not, choose the dropdown next to the AWS Region name and choose the AWS Region that you want to use.
# Choose Add cluster, and then choose Create. If you don't see this option, then choose Clusters in the left navigation pane first.
# On the Configure cluster page, do the following:
# Enter a Name for your cluster, such as my-cluster. The name can contain only alphanumeric characters (case-sensitive) and hyphens. It must start with an alphabetic character and can't be longer than 100 characters.
# For Cluster Service Role, choose myAmazonEKSClusterRole.
# Leave the remaining settings at their default values and choose Next.
# On the Specify networking page, do the following:
# Choose the ID of the VPC that you created in a previous step from the VPC dropdown list. It is something like vpc-00x0000x000x0x000 | my-eks-vpc-stack-VPC.
# Leave the remaining settings at their default values and choose Next.
# On the Configure logging page, choose Next.
# On the Review and create page, choose Create.
# To the right of the cluster's name, the cluster status is Creating for several minutes until the cluster provisioning process completes. Don't continue to the next step until the status is Active.


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
 --name ${EKS_CLUSTER_NAME}-2 \
 --version 1.27 \
 --region ${AWS_REGION} \
 --nodegroup-name standard-workers \
 --node-type t3.micro \
 --nodes 3 \
 --nodes-min 1 \
 --nodes-max 4 \
 --managed \
   --ssh-public-key ~/.ssh/id_rsa.pub \
  --vpc-private-subnets=subnet-076afdef0f9911f16,subnet-001ae6deda7adaf15 \
  --vpc-public-subnets=subnet-065bbff8f2e547c0e,subnet-078382a4e4f2333da

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