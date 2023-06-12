#!/bin/bash
gcloud container clusters upgrade example-cluster --node-pool=default-pool --cluster-version "v1.25.8-gke.500" --region us-east4-a

