helm repo add praqma https://praqma-helm-repo.s3.amazonaws.com/
helm repo update

helm install praqma/jira -f values.yaml --name jira
