#!/bin/bash
#Author: skondla.ai@gmail.com
#Purpose: Setup Prometheus and Grafana on GKE cluster for monitoring metrics

export EMAIL_ADDRESS=skondla.ai@gmail.com

kubectl apply -f namespace.yaml
kubectl apply -f prometheus-rbac.yaml
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=${EMAIL_ADDRESS}
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deploy.yaml
kubectl -f apply prometheus-svc.yaml
kubectl apply -f grafana.yaml
kubectl expose deployment grafana --type=LoadBalancer --namespace=monitoring
kubectl apply -f node-exporter.yaml
kubectl apply -f state-metrics-deploy.yaml
kubectl apply -f state-metrics-rbac.yaml

