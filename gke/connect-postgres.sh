#!/bin/bash

export POSTGRES_PASSWORD=$(kubectl get secret --namespace default jiradb-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
kubectl run jiradb-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:9.6 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host jiradb-postgresql -U jirauser -d jira -p 5432
