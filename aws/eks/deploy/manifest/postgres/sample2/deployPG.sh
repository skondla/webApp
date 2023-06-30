#!/bin/bash
#source ~/.secrets
export AWS_ACCOUNT_ID=`cat ~/.secrets | grep AWS_ACCOUNT_ID | awk '{print $2}'`
export PG_ROOT=`cat ~/.secrets | grep PG_ROOT | awk '{print $2}'`
envsubst < secret_pg.yaml | kubectl apply -f -
envsubst < csi_storage_class_pg.yaml | kubectl apply -f -
envsubst < csi_pvc_pg.yaml | kubectl apply -f -
#envsubst < pv_pg.yaml | kubectl apply -f -
#envsubst < pvc_pg.yaml | kubectl apply -f -
envsubst < deployment_pg.yaml | kubectl apply -f -
envsubst < service_pg.yaml | kubectl apply -f -
