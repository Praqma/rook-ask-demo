#!/bin/bash

kubectl create -f cephblock-storageclass.yaml
kubectl create -f blockpool.yaml