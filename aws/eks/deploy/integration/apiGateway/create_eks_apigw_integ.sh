#!/bin/bash
#Author:    skondla.ai@gmail.com
#Purpose:   This script will integrate Amazon API Gateway with Amazon EKS

#Set environment variables
export ECR_REPOSITORY="webapp1-demo-shop"
export AGW_EKS_CLUSTER_NAME="webapps-demo"
export APP_DIR="../../../app1/"
export AGW_ACCOUNT_ID=`cat ~/.secrets | grep 'AWS_ACCOUNT_ID' | awk '{print $2}'`
export AGW_AWS_REGION=`cat ~/.aws/config | grep region | awk '{print $3}'`
export AWS_ACCESS_KEY_ID=`cat ~/.aws/credentials|grep aws_access_key_id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`cat ~/.aws/credentials|grep aws_secret_access_key | awk '{print $3}'`
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AGW_AWS_REGION}.amazonaws.com"
export IMAGE_TAG=$(openssl rand -hex 32)
export ECR_REPOSITORY_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
export EKS_APP_NAME="webapp1-demo-shop"
export EKS_SERVICE="webapp1"
export EKS_SERVICE_ACCOUNT="webapp1-sa"
export EKS_NAMESPACE="webapp"
export APP_MANIFEST_DIR="../../manifest/webapp1"
export IMAGE_NAME=`cat ~/Downloads/webapp_ecr_image.txt | grep imageName|awk '{print $2}'`
export EKS_PRIVATE_SUBNET1="subnet-02b74b454744a8394"
export EKS_PRIVATE_SUBNET2="subnet-0adda7ae20f26f1d5"
export EKS_PUBLIC_SUBNET1="subnet-0635302237d16e28a"
export EKS_PUBLIC_SUBNET2="subnet-0be1b29a1c6677f00"

#Create a new EKS cluster using eksctl:

# eksctl create cluster \
#  --name ${EKS_CLUSTER_NAME} \
#  --version 1.27 \
#  --region ${AGW_AWS_REGION} \
#  --nodegroup-name standard-workers \
#  --node-type t3.micro \
#  --nodes 4 \
#  --nodes-min 3 \
#  --nodes-max 6 \
#  --managed \
#  --ssh-public-key ~/.ssh/id_rsa.pub \
#  --vpc-private-subnets=${EKS_PRIVATE_SUBNET1},${EKS_PRIVATE_SUBNET2} \
#  --vpc-public-subnets=${EKS_PUBLIC_SUBNET1},${EKS_PUBLIC_SUBNET2} 

# aws eks update-kubeconfig \
#  --region ${AGW_AWS_REGION} \
#  --name ${EKS_CLUSTER_NAME}

# kubectl get svc

#Create API Gateway IAM policy - make sure to adjust to reflect least privilege

cat > apigateway_fullaccess.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "apigateway:*"
            ],
            "Resource": "arn:aws:apigateway:*::/*"
        }
    ]
}
EOF

aws iam create-role --role-name fullAccessAPIGatewayRole --assume-role-policy-document file://"apigateway_fullaccess.json"

aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator --role-name fullAccessAPIGatewayRole

## Associate OIDC provider 
eksctl utils associate-iam-oidc-provider \
  --region $AGW_AWS_REGION \
  --cluster $AGW_EKS_CLUSTER_NAME \
  --approve


## Download the IAM policy document
curl -S https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json -o iam-policy.json

## Create an IAM policy 
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy-APIGWDEMO \
  --policy-document file://iam-policy.json 2> /dev/null

## Create a service account 
eksctl create iamserviceaccount \
  --cluster=$AGW_EKS_CLUSTER_NAME \
  --region $AGW_AWS_REGION \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --override-existing-serviceaccounts \
  --attach-policy-arn=arn:aws:iam::${AGW_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy-APIGWDEMO \
  --approve
  
## Get EKS cluster VPC ID
export AGW_VPC_ID=$(aws eks describe-cluster \
  --name $AGW_EKS_CLUSTER_NAME \
  --region $AGW_AWS_REGION  \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

# helm repo add eks https://aws.github.io/eks-charts && helm repo update
# kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
# helm install aws-load-balancer-controller \
#   eks/aws-load-balancer-controller \
#   --namespace kube-system \
#   --set clusterName=$AGW_EKS_CLUSTER_NAME \
#   --set serviceAccount.create=false \
#   --set serviceAccount.name=aws-load-balancer-controller \
#   --set vpcId=$AGW_VPC_ID\
#   --set region=$AGW_AWS_REGION


helm repo add eks https://aws.github.io/eks-charts && helm repo update
# If using IAM Roles for service account install as follows -  NOTE: you need to specify both of the chart values `serviceAccount.create=false` and `serviceAccount.name=aws-load-balancer-controller`
helm install aws-load-balancer-controller \
 eks/aws-load-balancer-controller \
 --namespace kube-system \
 --set clusterName=$AGW_EKS_CLUSTER_NAME -n kube-system \
 --set serviceAccount.create=false \
 --set serviceAccount.name=aws-load-balancer-controller \
 --set vpcId=$AGW_VPC_ID \
 --set region=$AGW_AWS_REGION

# If not using IAM Roles for service account
# helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#  --set clusterName=$AGW_EKS_CLUSTER_NAME -n kube-system

#Deploy the ACK Controller for API Gateway

#Create a service account for ACK:

curl -O https://raw.githubusercontent.com/aws-samples/amazon-apigateway-ingress-controller-blog/Mainline/apigw-ingress-controller-blog/ack-iam-policy.json

aws iam create-policy \
  --policy-name ACKIAMPolicy \
  --policy-document file://ack-iam-policy.json

eksctl create iamserviceaccount \
  --attach-policy-arn=arn:aws:iam::${AGW_ACCOUNT_ID}:policy/ACKIAMPolicy \
  --cluster=$AGW_EKS_CLUSTER_NAME \
  --namespace=kube-system \
  --name=ack-apigatewayv2-controller \
  --override-existing-serviceaccounts \
  --region $AGW_AWS_REGION \
  --approve

export HELM_EXPERIMENTAL_OCI=1
export SERVICE=apigatewayv2
export RELEASE_VERSION=v0.0.2
export CHART_REPO=oci://public.ecr.aws/aws-controllers-k8s
export CHART_REF="$CHART_REPO/$SERVICE --version $RELEASE_VERSION"

helm chart pull $CHART_REF

# Install ACK

# Please note that the ECR Public Endpoints are available in "us-east-1" 
# and "us-west-2". The region value in this command does not need to be
# updated to the region where you are planning to deploy the resources.
# https://docs.aws.amazon.com/general/latest/gr/ecr-public.html#ecr-public-region
aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws

# The region value in this command should reflect the region where you
# are planning to deploy the resources.
helm install \
  --namespace kube-system \
  ack-$SERVICE-controller \
  $CHART_REPO/$SERVICE-chart \
  --version=$RELEASE_VERSION \
  --set=aws.region=$AGW_AWS_REGION

#Deploy the webapp1-demo-shop application
#kubectl apply -f https://github.com/aws-samples/amazon-apigateway-ingress-controller-blog/raw/Mainline/apigw-ingress-controller-blog/echoserver.yml
#kubectl apply -f https://github.com/aws-samples/amazon-apigateway-ingress-controller-blog/raw/Mainline/apigw-ingress-controller-blog/author-deployment.yml

envsubst < ${APP_MANIFEST_DIR}/webapp1.yaml | kubectl apply -f -
envsubst < ${APP_MANIFEST_DIR}/Service.yaml | kubectl apply -f -
envsubst < ${APP_MANIFEST_DIR}/Deployment.yaml | kubectl apply -f -


#Create API Gateway resources

AGW_VPCLINK_SG=$(aws ec2 create-security-group \
  --description "SG for VPC Link" \
  --group-name SG_VPC_LINK \
  --vpc-id $AGW_VPC_ID \
  --region $AGW_AWS_REGION \
  --output text \
  --query 'GroupId')

#Create a VPC Link for the internal NLB:

cat > vpclink.yaml<<EOF
apiVersion: apigatewayv2.services.k8s.aws/v1alpha1
kind: VPCLink
metadata:
  name: nlb-internal
spec:
  name: nlb-internal
  securityGroupIDs: 
    - $AGW_VPCLINK_SG
  subnetIDs: 
    - $(aws ec2 describe-subnets \
          --filter Name=tag:kubernetes.io/role/internal-elb,Values=1 \
          --query 'Subnets[0].SubnetId' \
          --region $AGW_AWS_REGION --output text)
    - $(aws ec2 describe-subnets \
          --filter Name=tag:kubernetes.io/role/internal-elb,Values=1 \
          --query 'Subnets[1].SubnetId' \
          --region $AGW_AWS_REGION --output text)
    - $(aws ec2 describe-subnets \
          --filter Name=tag:kubernetes.io/role/internal-elb,Values=1 \
          --query 'Subnets[2].SubnetId' \
          --region $AGW_AWS_REGION --output text)
EOF
kubectl apply -f vpclink.yaml

#Depending on your AWS Region, you may need to modify the VPC link manifest above to exclude subnets in AZs that don’t support VPC link. 
#You can find the offending subnet by checking the log output of the ACK pod.

kubectl -n kube-system logs ack-apigatewayv2-controller-XXXX | grep ERROR


#The VPC link can take a few minutes to become available. You can check its status using AWS CLI:

sleep 120

aws apigatewayv2 get-vpc-links --region $AGW_AWS_REGION

#Once the VPC link is available, we can proceed to create an API Gateway API. We’ll create a manifest for API configuration that ACK will use to create an API. 
#The uri field for each path will map to the ARN of NLB listeners.

cat > apigw-api.yaml<<EOF
apiVersion: apigatewayv2.services.k8s.aws/v1alpha1
kind: API
metadata:
  name: apitest-private-nlb
spec:
  body: '{
              "openapi": "3.0.1",
              "info": {
                "title": "ack-apigwv2-import-test-private-nlb",
                "version": "v1"
              },
              "paths": {
              "/\$default": {
                "x-amazon-apigateway-any-method" : {
                "isDefaultRoute" : true,
                "x-amazon-apigateway-integration" : {
                "payloadFormatVersion" : "1.0",
                "connectionId" : "$(kubectl get vpclinks.apigatewayv2.services.k8s.aws \
  nlb-internal \
  -o jsonpath="{.status.vpcLinkID}")",
                "type" : "http_proxy",
                "httpMethod" : "GET",
                "uri" : "$(aws elbv2 describe-listeners \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
  --region $AGW_AWS_REGION \
  --query "LoadBalancers[?contains(DNSName, '$(kubectl get service authorservice \
  -o jsonpath="{.status.loadBalancer.ingress[].hostname}")')].LoadBalancerArn" \
  --output text) \
  --region $AGW_AWS_REGION \
  --query "Listeners[0].ListenerArn" \
  --output text)",
               "connectionType" : "VPC_LINK"
                  }
                }
              },
              "/meta": {
                  "get": {
                    "x-amazon-apigateway-integration": {
                       "uri" : "$(aws elbv2 describe-listeners \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
  --region $AGW_AWS_REGION \
  --query "LoadBalancers[?contains(DNSName, '$(kubectl get service echoserver \
  -o jsonpath="{.status.loadBalancer.ingress[].hostname}")')].LoadBalancerArn" \
  --output text) \
  --region $AGW_AWS_REGION \
  --query "Listeners[0].ListenerArn" \
  --output text)",
                      "httpMethod": "GET",
                      "connectionId": "$(kubectl get vpclinks.apigatewayv2.services.k8s.aws \
  nlb-internal \
  -o jsonpath="{.status.vpcLinkID}")",
                      "type": "HTTP_PROXY",
                      "connectionType": "VPC_LINK",
                      "payloadFormatVersion": "1.0"
                    }
                  }
                }
              },
              "components": {}
        }'
EOF
kubectl apply -f apigw-api.yaml

#Each route in API Gateway has an associated NLB (or ALB) listener. The $default route maps to the listener of the NLB for the authorservice. 
#Similarly, the /meta maps to the listener of the echoserver NLB

echo "
apiVersion: apigatewayv2.services.k8s.aws/v1alpha1
kind: Stage
metadata:
  name: "apiv1"
spec:
  apiID: $(kubectl get apis.apigatewayv2.services.k8s.aws apitest-private-nlb -o=jsonpath='{.status.apiID}')
  stageName: api
  autoDeploy: true
" | kubectl apply -f -

#ACK populates API resources’ metadata fields to include the API Endpoint and API ID. You can use kubectl to query this information:

kubectl describe api apitest-private-nlb

#Invoke the API

kubectl get api apitest-private-nlb -o jsonpath="{.status.apiEndpoint}"

#Invoke the authorservice service:

curl $(kubectl get api apitest-private-nlb -o jsonpath="{.status.apiEndpoint}")/api/author/

#Invoke the echoserver service by invoking the meta path

curl $(kubectl get api apitest-private-nlb -o jsonpath="{.status.apiEndpoint}")/api/meta


