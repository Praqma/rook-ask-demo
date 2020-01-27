#!/bin/bash

kubectl apply -f jira-service-main.yaml
kubectl apply -f jira-ingress.yaml

helm repo add praqma https://praqma-helm-repo.s3.amazonaws.com/
helm repo update

helm install jira praqma/jira -f jira-values.yaml
