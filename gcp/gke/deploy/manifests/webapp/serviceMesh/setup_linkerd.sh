#!/bin/bash

curl https://run.linkerd.io/emojivoto.yml --output manifest.yaml
cat manifest.yaml | less
kubectl apply -f manifest.yaml
kubectl get -n emojivoto pods
sleep 30
#kubectl get -n emojivoto deploy -o yaml | linkerd inject - | kubectl apply -f -
kubectl -n emojivoto port-forward svc/web-svc 8080:80
# http://localhost:8080
curl https://run.linkerd.io/install | sh
~/.linkerd2/bin/linkerd version
export PATH=$PATH:$HOME/.linkerd2/bin
linkerd version
linkerd install --crds | kubectl apply -f -
linkerd upgrade --crds | kubectl apply -f -
linkerd check
#linkerd dashboard
linkerd stat deployments -n linkerd
linkerd stat deployments -n emojivoto
linkerd stat deployments -n webapp1-namespace
kubectl get deployments -n emojivoto -o yaml | linkerd inject - | kubectl apply -f -
kubectl get deployments -n webapp1-namespace -o yaml | linkerd inject - | kubectl apply -f -