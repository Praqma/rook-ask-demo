#!/bin/bash

helm delete postgres-jira
sleep 5
kubectl delete pvc data-postgres-jira-postgresql-0