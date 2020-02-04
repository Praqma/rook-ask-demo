#!/bin/bash

kubectl delete -f jira-service-main.yaml
kubectl delete -f jira-ingress.yaml
helm delete jira

