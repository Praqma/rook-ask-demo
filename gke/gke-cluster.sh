#!/bin/bash

# Default values
CLUSTER_NAME=""
NUM_NODES=5
DISK_SIZE=100

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-h] [-d NAME] [-c NAME] [-s DISK_SIZE] [-n NUM_NODES]...

Creation and deletion of a GKE "Alpha Cluster" for demo of rook-ask with specified name, number of nodes and disk size.
GKE Alpha cluster enable ALL Kuberntes "Alpha" features.

NOTE: That Alpha cluster are not covered by SLA, are deleted after 30 days, and are not auto upgraded.

  -h                Display this help and exit 0.
  -c <NAME>         Create the cluster. The <NAME> of the cluster is REQUIRED.
  -d <NAME>         Delete the cluster. The <NAME> of the cluster is REQUIRED.
  -n <NUM_NODES>    The number of nodes. If not specified defaults to 5.
  -s <DISK_SIZE>    The disk size for the nodes. If not specified defaults to 100 Gb.
EOF
}

create_cluster() {
  gcloud beta container clusters create --quiet $CLUSTER_NAME \
  --enable-kubernetes-alpha \
  --cluster-version 1.15.8-gke.2 \
  --zone europe-west1-b \
  --image-type ubuntu \
  --machine-type n1-standard-4 \
  --num-nodes $NUM_NODES \
  --disk-type "pd-standard" \
  --disk-size $DISK_SIZE \
  --node-labels preemptive=false \
  --metadata disable-legacy-endpoints=true \
  --no-enable-ip-alias \
  --no-enable-autorepair \
  --no-enable-autoupgrade \
  --no-enable-stackdriver-kubernetes
}

delete_cluster(){
  gcloud container clusters delete $CLUSTER_NAME --zone europe-west1-b
}

OPTIND=1
# Resetting OPTIND is necessary if getopts was used previously in the script.
# It is a good idea to make OPTIND local if you process options in a function.

while getopts hc:d:s:n: opt; do
  case $opt in
    h)
      show_help
      exit 0
      ;;
    c)
      CLUSTER_NAME="$OPTARG"
      if [ "$CLUSTER_NAME" == "" ]; then
        echo "You must provide a cluster name!"
        show_help
        exit 1
      fi
      create_cluster
      ;;
    d)
      CLUSTER_NAME="$OPTARG"
      if [ "$CLUSTER_NAME" == "" ]; then
        echo "You must provide a cluster name!"
        show_help
        exit 1
      fi
      delete_cluster
      ;;
    n)
      NUM_NODES=$OPTARG
      ;;
    s)
      DISK_SIZE=$OPTARG
      ;;
    *)
      show_help
      exit 1
      ;;
  esac
done
shift "$((OPTIND-1))"   # Discard the options and sentinel --

# End of file