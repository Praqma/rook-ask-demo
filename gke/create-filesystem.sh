#!/bin/bash

kubectl create -f cephfs-storageclass.yaml
kubectl create -f shared-fs.yaml