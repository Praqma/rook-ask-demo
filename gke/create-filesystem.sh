#!/bin/bash
kubectl create -f cephblock-storageclass.yaml
kubectl create -f blockpool.yaml

sleep 3

kubectl create -f cephfs-storageclass.yaml
kubectl create -f shared-fs.yaml