#!/bin/bash
#Purpose: Setup Anthos Service Mesh

# Set parameters
export GKE_PROJECT=${GCP_PROJECT_ID}
export GKE_CLUSTER="webapp1-demo-cluster"
export GKE_APP_NAME="webapp1-demo-shop"
export GKE_SERVICE="webapp1-service"
export GKE_SERVICE_ACCOUNT="webapp1-serviceaccount"
export GKE_DEPLOYMENT_NAME="webapp1-deployment"
export MANIFESTS_DIR="deploy/manifests/webapp"
export APP_DIR="../../app1/"
export GKE_NAMESPACE="webapp1-namespace"
export GKE_APP_PORT="25443"
export MEMBERSHIP_NAME="webapp1-membership"

# Get a list of regions:
# $ gcloud compute regions list
#
# Get a list of zones:
# $ gcloud compute zones list
export GKE_REGION="us-east4"
export GKE_ZONE="us-east4-a"
export GKE_ADDITIONAL_ZONE="us-east4-b"

#Set Compute Zone
gcloud config set compute/zone ${GKE_ZONE}

#Check pre-requisites
curl -sL https://github.com/GoogleCloudPlatform/anthos-sample-deployment/releases/latest/download/asd-prereq-checker.sh | sh -

##Setup anthos 

#gcloud container clusters create CLUSTER_NAME \
#    --region=COMPUTE_REGION \
#   --workload-pool=PROJECT_ID.svc.id.goog

#Registering a GKE cluster using Workload Identity (recommended)

gcloud container fleet memberships register ${MEMBERSHIP_NAME} \
 --gke-cluster=${GKE_ZONE}/${GKE_CLUSTER} \
 --enable-workload-identity

#Registering a GKE cluster using a Service Account

gcloud container fleet memberships register ${MEMBERSHIP_NAME} \
 --gke-cluster=${GKE_ZONE}/${GKE_CLUSTER} \
 --service-account-key-file=~/.private/key.json \
 --install-connect-agent

