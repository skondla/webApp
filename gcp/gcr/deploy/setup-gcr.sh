#!/bin/bash
#Author: skondla@me.com
#Purpose: Create a new instance of GCR artifact repository

# Create a project and set GKE_PROJECT to the project id:
# See https://console.cloud.google.com/projectselector2/home/dashboard

# Set parameters
source ~/.bash_profile
gcloud auth login
# Set parameters
export GKE_PROJECT=`gcloud config get project`
export GKE_CLUSTER="webapp1-demo-cluster"
export GKE_APP_NAME="webapp1-demo-shop"
export GKE_SERVICE="webapp1-service"
export GKE_SERVICE_ACCOUNT="webapp1-serviceaccount"
export GKE_DEPLOYMENT_NAME="webapp1-deployment"
export MANIFESTS_DIR="manifests/webapp"
export APP_DIR="../../../app1/"
export GKE_NAMESPACE="webapp1-namespace"
export GKE_APP_PORT="25443"

# Get a list of regions:
# $ gcloud compute regions list
#
# Get a list of zones:
# $ gcloud compute zones list
export GKE_REGION="us-east4"
export GKE_ZONE="us-east4-a"
export GKE_ADDITIONAL_ZONE="us-east4-b"

# Just a placeholder for the first deployment
#export IMAGE_TAG=$(openssl rand -hex 32)
#export GITHUB_SHA=${IMAGE_TAG}

gcloud config set project $GKE_PROJECT
gcloud config set compute/zone $GKE_ZONE
#gcloud config set compute/zone $GKE_ADDITIONAL_ZONE
gcloud config set compute/region $GKE_REGION

# enable API
gcloud services enable \
 compute.googleapis.com \
 containerregistry.googleapis.com \
 container.googleapis.com \
 artifactregistry.googleapis.com

# Create repository
gcloud artifacts repositories create $GKE_PROJECT \
  --repository-format=docker \
  --location=$GKE_REGION \
  --description="Docker repository"


