#!/bin/bash

helm delete jiradb
sleep 5
kubectl delete pvc data-jiradb-postgresql-0