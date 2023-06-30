#!/bin/bash

aws cloudformation describe-stacks --stack-name ${EKS_APP_NAME}-stack --query "Stacks[0].Outputs[0].OutputValue" --output text > ~/Downloads/cf_stack.output
aws cloudformation describe-stacks --stack-name ${EKS_APP_NAME}-stack --query "Stacks[0].Outputs[1].OutputValue" --output text >> ~/Downloads/cf_stack.output 
aws cloudformation describe-stacks --stack-name ${EKS_APP_NAME}-stack --query "Stacks[0].Outputs[2].OutputValue" --output text >> ~/Downloads/cf_stack.output
echo `cat ~/Downloads/cf_stack.output  | grep "subnet"` | { while read -d, i; do echo "$i"; done; echo "$i"; } > ~/Downloads/subnets.list
export VPC_ID=`cat ~/Downloads/cf_stack.output  | grep "vpc"`

export IGW_ID=`aws ec2 describe-internet-gateways \
  --filters Name=attachment.vpc-id,Values=${VPC_ID} \
  --query "InternetGateways[].InternetGatewayId" \
  | jq -r '.[0]'`

export PUBLIC_SUBNETS=`aws ec2 describe-route-tables \
  --query  'RouteTables[*].Associations[].SubnetId' \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
    "Name=route.gateway-id,Values=${IGW_ID}" \
  | jq . -c`
  
for subnet in `cat ~/Downloads/subnets.list` ; do echo "subnet: $subnet"; done