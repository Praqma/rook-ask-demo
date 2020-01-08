#!/bin/bash

helm repo add praqma https://praqma-helm-repo.s3.amazonaws.com/
helm repo update

helm install jira jira -f jira/jira-values.yaml
