#!/bin/bash

# Set parameters
source ~/.bash_profile
export GKE_PROJECT=${GCP_PROJECT_ID} #env variable from  ~/.secrets
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

gcloud config set project $GKE_PROJECT

# Delete the cluster
gcloud container clusters delete $GKE_CLUSTER --region $GKE_ZONE

# Delete service account
gcloud iam service-accounts delete "$GKE_SERVICE_ACCOUNT@$GKE_PROJECT.iam.gserviceaccount.com"

# Delete repository
gcloud artifacts repositories delete $GKE_PROJECT --location $GKE_REGION