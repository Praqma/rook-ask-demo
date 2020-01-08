#!/bin/bash

#kubectl create namespace rook-ceph
kubectl create -f common.yaml
kubectl create -f operator.yaml
#helm install --namespace rook-ceph rook-ask rook-release/rook-ceph --set rbacEnable=false