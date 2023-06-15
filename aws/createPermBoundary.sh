#!/bin/bash

aws cloudformation create-stack \
 --stack-name webapp1-demo-shop \
 --template-body file://${PWD}/PermissionBoundary.yaml \
 --capabilities CAPABILITY_NAMED_IAM \
 --parameters ParameterKey=DockerAuth,ParameterValue={}
