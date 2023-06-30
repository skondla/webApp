#!/bin/bash
#Author:    skondla.ai@gmail.com
#Purpose:   This script will destroy services that integrated Amazon API Gateway with Amazon EKS

#Set environment variables
export ECR_REPOSITORY="webapp1-demo-shop"
export AGW_EKS_CLUSTER_NAME="webapps-demo"
export APP_DIR="../../../app1/"
export AGW_ACCOUNT_ID=`cat ~/.secrets | grep 'AWS_ACCOUNT_ID' | awk '{print $2}'`
export AGW_AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export IMAGE_TAG=$(openssl rand -hex 32)
export ECR_REPOSITORY_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
export EKS_APP_NAME="webapp1-demo-shop"
export EKS_SERVICE="webapp1"
export EKS_SERVICE_ACCOUNT="webapp1-sa"
export EKS_NAMESPACE="webapp"
export APP_MANIFEST_DIR="../../manifest/webapp1"
export IMAGE_NAME=`cat ~/Downloads/webapp_ecr_image.txt | grep imageName|awk '{print $2}'`

kubectl delete stages.apigatewayv2.services.k8s.aws apiv1 
kubectl delete apis.apigatewayv2.services.k8s.aws apitest-private-nlb
kubectl delete vpclinks.apigatewayv2.services.k8s.aws nlb-internal 
kubectl delete service echoserver
kubectl delete services authorservice
sleep 10
aws ec2 delete-security-group --group-id $AGW_VPCLINK_SG --region $AGW_AWS_REGION 
helm delete aws-load-balancer-controller --namespace kube-system
helm delete ack-apigatewayv2-controller --namespace kube-system
for role in $(aws iam list-roles --query "Roles[?contains(RoleName, \
  'eksctl-eks-ack-apigw-addon-iamserviceaccount')].RoleName" \
  --output text)
do (aws iam detach-role-policy --role-name $role --policy-arn $(aws iam list-attached-role-policies --role-name $role --query 'AttachedPolicies[0].PolicyArn' --output text))
done
for role in $(aws iam list-roles --query "Roles[?contains(RoleName, \
  'eksctl-eks-ack-apigw-addon-iamserviceaccount')].RoleName" \
  --output text)
do (aws iam delete-role --role-name $role)
done
sleep 5
aws iam delete-policy --policy-arn $(echo $(aws iam list-policies --query 'Policies[?PolicyName==`ACKIAMPolicy`].Arn' --output text))
aws iam delete-policy --policy-arn $(echo $(aws iam list-policies --query 'Policies[?PolicyName==`AWSLoadBalancerControllerIAMPolicy-APIGWDEMO`].Arn' --output text))
eksctl delete cluster --name $AGW_EKS_CLUSTER_NAME --region $AGW_AWS_REGION
