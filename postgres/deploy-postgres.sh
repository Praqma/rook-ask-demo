helm install --name postgres-jira \
  --set image=postgres                  \
  --set imageTag=9.6.2                  \
  --set metrics.enabled=true            \
  --set postgresDatabase="jira"   \
  --set postgresUser="jirauser"   \
  --set postgresPassword="jira_password"        \
  --set persistence.storageClass="rook-ceph-block" \
  --set postgresInitdbArgs="--encoding='UTF8' --lc-collate='C' --lc-ctype='C'" \
  --set resources.requests.memory=1024m  \
  --set resources.requests.cpu=1512m     \
  --version 1.0.0 \
stable/postgresql

