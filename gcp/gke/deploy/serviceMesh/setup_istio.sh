#!/bin/bash
#purpose: This example shows how to configure a multicluster mesh with a single-network deployment over 2 Google Kubernetes Engine clusters.
#Create the GKE Clusters
#Reference: https://istio.io/docs/setup/kubernetes/multicluster-install/
#Reference: https://istio.io/v1.3/docs/examples/multicluster/gke/

#Set the default project for gcloud to perform actions on:

gcloud config set project ${GCP_PROJECT_ID}
proj=$(gcloud config list --format='value(core.project)')

#Create 2 GKE clusters for use with the multicluster feature. 
#Note: --enable-ip-alias is required to allow inter-cluster direct pod-to-pod communication. The zone value must be one of the GCP zones.

zone="us-east1-b"
cluster="cluster-1"
gcloud container clusters create $cluster --zone $zone --username "admin" \
  --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
  --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
"https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
"https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
"https://www.googleapis.com/auth/trace.append" \
--num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --async
cluster="cluster-2"
gcloud container clusters create $cluster --zone $zone --username "admin" \
  --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
  --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
"https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
"https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
"https://www.googleapis.com/auth/trace.append" \
--num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --async

#Wait for clusters to transition to the RUNNING state by polling their statuses via the following command:
gcloud container clusters list

#Get the clusters’ credentials (command details):

gcloud container clusters get-credentials cluster-1 --zone $zone
gcloud container clusters get-credentials cluster-2 --zone $zone

#Validate kubectl access to each cluster and create a cluster-admin cluster role binding tied to the Kubernetes credentials associated with your GCP user.
#For cluster-1
kubectl config use-context "gke_${proj}_${zone}_cluster-1"
kubectl get pods --all-namespaces
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
#For cluster-2
kubectl config use-context "gke_${proj}_${zone}_cluster-2"
kubectl get pods --all-namespaces
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"

#Create a Google Cloud firewall rule
#To allow the pods on each cluster to directly communicate, create the following rule:

function join_by { local IFS="$1"; shift; echo "$*"; }
ALL_CLUSTER_CIDRS=$(gcloud container clusters list --format='value(clusterIpv4Cidr)' | sort | uniq)
ALL_CLUSTER_CIDRS=$(join_by , $(echo "${ALL_CLUSTER_CIDRS}"))
ALL_CLUSTER_NETTAGS=$(gcloud compute instances list --format='value(tags.items.[0])' | sort | uniq)
ALL_CLUSTER_NETTAGS=$(join_by , $(echo "${ALL_CLUSTER_NETTAGS}"))
gcloud compute firewall-rules create istio-multicluster-test-pods \
  --allow=tcp,udp,icmp,esp,ah,sctp \
  --direction=INGRESS \
  --priority=900 \
  --source-ranges="${ALL_CLUSTER_CIDRS}" \
  --target-tags="${ALL_CLUSTER_NETTAGS}" --quiet

#Install the Istio control plane
#The following generates an Istio installation manifest, installs it, and enables automatic sidecar injection in the default namespace:
kubectl config use-context "gke_${proj}_${zone}_cluster-1"
helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio_master.yaml
kubectl create ns istio-system
helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
kubectl apply -f $HOME/istio_master.yaml
kubectl label namespace default istio-injection=enabled
#Wait for pods to come up by polling their statuses via the following command:
kubectl get pods -n istio-system

#Generate remote cluster manifest
#Get the IPs of the control plane pods:
export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
#Generate remote cluster manifest:
helm template install/kubernetes/helm/istio \
  --namespace istio-system --name istio-remote \
  --values install/kubernetes/helm/istio/values-istio-remote.yaml \
  --set global.remotePilotAddress=${PILOT_POD_IP} \
  --set global.remotePolicyAddress=${POLICY_POD_IP} \
  --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > $HOME/istio-remote.yaml

#Install remote cluster manifest
#The following installs the minimal Istio components and enables automatic sidecar injection on the namespace default in the remote cluster:
kubectl config use-context "gke_${proj}_${zone}_cluster-2"
kubectl create ns istio-system
kubectl apply -f $HOME/istio-remote.yaml
kubectl label namespace default istio-injection=enabled

#Create remote cluster’s kubeconfig for Istio Pilot
#The istio-remote Helm chart creates a service account with minimal access for use by Istio Pilot discovery.
#Prepare environment variables for building the kubeconfig file for the service account istio-multi:

export WORK_DIR=$(pwd)
CLUSTER_NAME=$(kubectl config view --minify=true -o jsonpath='{.clusters[].name}')
CLUSTER_NAME="${CLUSTER_NAME##*_}"
export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
SERVER=$(kubectl config view --minify=true -o jsonpath='{.clusters[].cluster.server}')
NAMESPACE=istio-system
SERVICE_ACCOUNT=istio-multi
SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['ca\.crt']}")
TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['token']}" | base64 --decode)
#Create a kubeconfig file in the working directory for the service account istio-multi:
cat <<EOF > ${KUBECFG_FILE}
apiVersion: v1
clusters:
   - cluster:
       certificate-authority-data: ${CA_DATA}
       server: ${SERVER}
     name: ${CLUSTER_NAME}
contexts:
   - context:
       cluster: ${CLUSTER_NAME}
       user: ${CLUSTER_NAME}
     name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
kind: Config
preferences: {}
users:
   - name: ${CLUSTER_NAME}
     user:
       token: ${TOKEN}
EOF

#Configure Istio control plane to discover the remote cluster
#Create a secret and label it properly for each remote cluster:

kubectl config use-context "gke_${proj}_${zone}_cluster-1"
kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}

#Deploy Bookinfo Example Across Clusters

kubectl config use-context "gke_${proj}_${zone}_cluster-1"
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl delete deployment reviews-v3

#Create the reviews-v3.yaml manifest for deployment on the remote:

cat <<EOF > $(pwd)/reviews-v3.yaml
---
##################################################################################################
# Ratings service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: ratings
  labels:
    app: ratings
spec:
  ports:
  - port: 9080
    name: http
---
##################################################################################################
# Reviews service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: reviews
  labels:
    app: reviews
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: reviews
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v3
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v3
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v3:1.5.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
EOF

#Deploy the reviews-v3.yaml manifest on the remote cluster:

kubectl config use-context "gke_${proj}_${zone}_cluster-2"
kubectl apply -f $(pwd)/reviews-v3.yaml

#Get the istio-ingressgateway service’s external IP to access the bookinfo page 
#to validate that Istio is including the remote’s reviews-v3 instance in the load balancing of reviews versions:

kubectl config use-context "gke_${proj}_${zone}_cluster-1"
kubectl get svc istio-ingressgateway -n istio-system


##Uninstall Istio

##Delete the Google Cloud firewall rule:

#gcloud compute firewall-rules delete istio-multicluster-test-pods --quiet

##Delete the cluster-admin cluster role binding from each cluster no longer being used for Istio:

#kubectl delete clusterrolebinding gke-cluster-admin-binding

##Delete any GKE clusters no longer in use. The following is an example delete command for the remote cluster, cluster-2:

#gcloud container clusters delete cluster-2 --zone $zone
