
#!/bin/bash
#Author: skondla.ai@gmail.com
#Purpose: Delete instance of GCR artifact repository

# Create a project and set GKE_PROJECT to the project id:
# See https://console.cloud.google.com/projectselector2/home/dashboard

# Set parameters
source ~/.bash_profile
gcloud auth login
# Set parameters
export GKE_PROJECT=`gcloud config get project`
 #env variable from  ~/.secrets
export GKE_ARTIFACTS_REPO="${GKE_PROJECT}"
export GKE_CLUSTER="webapp1-demo-cluster"
export GKE_APP_NAME="webapp1-demo-shop"
export GKE_SERVICE="webapp1-service"
export GKE_SERVICE_ACCOUNT="webapp1-serviceaccount"
export GKE_DEPLOYMENT_NAME="webapp1-deployment"
export MANIFESTS_DIR="deploy/manifests/webapp"
export APP_DIR="../../app1/"
export GKE_NAMESPACE="webapp1-namespace"
export GKE_APP_PORT="25443"
export GKE_REGION="us-east4"
export GKE_ZONE="us-east4-a"
export GKE_ADDITIONAL_ZONE="us-east4-b"

#gcloud config set project $GKE_PROJECT

#Describe repository

gcloud artifacts repositories describe ${GKE_ARTIFACTS_REPO} --location=${GKE_REGION}

# Delete repository
gcloud artifacts repositories delete $GKE_PROJECT --location $GKE_REGION --async