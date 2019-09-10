kubectl create ns metallb
kubectl apply -f metallb.conf.yaml
helmsman -apply -f traefik-helmsman.yaml
