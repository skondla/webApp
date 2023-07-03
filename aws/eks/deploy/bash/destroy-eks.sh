#!/bin/bash
#Author: skondla@me.com
#Purpose: Destroy a new instance of EKS cluster 
#enviroment variables
export EKS_CLUSTER_NAME="webapps-demo"
#export APP_DIR="../../../app1/"
export AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
export AWS_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`

aws sts get-caller-identity

eksctl delete cluster --name=${EKS_CLUSTER_NAME} --region=${AWS_REGION}


#Delelte roles
aws iam detach-role-policy --role-name myAmazonEKSClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam detach-role-policy --role-name fullAccessEKSClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam detach-role-policy --role-name AmazonEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam detach-role-policy --role-name AmazonEKSClusterPolicy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam detach-role-policy --role-name AmazonEKSServicePolicy --policy-arn arn:aws:iam::aws:policy/AmazonEKSServicePolicy
aws iam detach-role-policy --role-name AmazonEKSClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam detach-role-policy --role-name eks_admin --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy


aws iam delete-role --role-name myAmazonEKSClusterRole
aws iam delete-role --role-name fullAccessEKSClusterRole 
aws iam delete-role --role-name AmazonEKSNodeRole
aws iam delete-role --role-name AmazonEKSClusterPolicy
aws iam delete-role --role-name AmazonEKSServicePolicy
aws iam delete-role --role-name AmazonEKSClusterRole
aws iam delete-role --role-name eks_admin 


