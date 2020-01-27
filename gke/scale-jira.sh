#!/bin/bash

# Global values
WANTED_REPLICAS=""        # Stores the number of wanted replicas passed in as argument.
SCALE_VALUE=0             # Represents the difference between wanted and current replicas.
STATEFULSET="jira"
PVC_PREFIX="jira-persistent-storage"

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-h] [-n WANTED_REPLICAS]...

Scale ASK Jira on GKE.

  -h                    Display this help and exit 0.
  -n <WANTED_REPLICAS>  The number of replicas. REQUIRED.
EOF
}

delete_snapshot() {
  echo "Deleting old snapshot leftover from previous scale run..."
  local old_snap=$(kubectl get VolumeSnapshot -o jsonpath="{.items[*].metadata.name}" | grep -o 'jira-home-snapshot')
  if [ "$old_snap" == "jira-home-snapshot" ]; then
      kubectl delete volumeSnapshot jira-home-snapshot > /dev/null 2>&1
  fi
}

create_snapshot() {
  echo "Creating fresh snapshot of jira-0 home directory..."
  local base_pvc=$1

  # Apply any changes to snapshot class yaml file.
  kubectl apply -f snapshotclass.yaml > /dev/null 2>&1

  # Create a snapshot of the pvc
  kubectl apply -f > /dev/null 2>&1 - << EOF
apiVersion: snapshot.storage.k8s.io/v1alpha1
kind: VolumeSnapshot
metadata:
  name: jira-home-snapshot
spec:
  snapshotClassName: csi-rbdplugin-snapclass
  source:
    name: "$base_pvc"
    kind: PersistentVolumeClaim
EOF
}

pvc_exists() {
  local pvc_name=$1
  pvc_array=($(kubectl get pvc -o jsonpath="{.items[*].metadata.name}" | grep -o "$PVC_PREFIX-$STATEFULSET-[0-9]"))
  local found=1
  for i in "${pvc_array[@]}"; do
    if [[ $pvc_name =~ $i ]] ; then
      found=0
    fi
  done
  return $found
}

create_pvc() {
  local pvc_name=$1

  if (pvc_exists "$pvc_name"); then
    # Todo: Here we can choose to delete unbound existing pvc's and pv's and then recreate them if wanted.
    echo "WARNING: PVC ($pvc_name) already exists will not recreate it."
  else
    # Create the pvc based on the snapshot
    kubectl create -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "$pvc_name"
spec:
  storageClassName: rook-ceph-block
  dataSource:
    name: jira-home-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
EOF
    if [ ! $? -eq 0 ]; then
        echo "ERROR: New PVC ($pvc_name) creation failed!"
        exit 1
    fi
  fi
}

generate_pvcs() {
  local POD_ARRAY=()
  POD_ARRAY=($(kubectl get pods -o jsonpath="{.items[*].metadata.name}" | grep -o "jira-[[:digit:]]"))

  create_snapshot "$PVC_PREFIX-$STATEFULSET-0"

  for (( i = SCALE_VALUE; i > 0; i-- )); do
    local last_pod_number=""
    # Todo handle empty array.
    last_pod_number=$(echo "${POD_ARRAY[-1]}" | grep -o "[[:digit:]]")
    next_pod_number=$((last_pod_number + 1))
    POD_ARRAY+=("$STATEFULSET-$next_pod_number")
    PVC_ARRAY+=("$PVC_PREFIX-$STATEFULSET-$next_pod_number")
    create_pvc "$PVC_PREFIX-$STATEFULSET-$next_pod_number"
  done
}

scale_down() {
  # Chosen to not delete pvc's and pv's when scaling down. We can choose to refesh them in scale up scenarios if wanted.
  kubectl scale statefulsets jira --replicas=$WANTED_REPLICAS
}

scale_up() {
  delete_snapshot # For timing reasons we do NOT delete the snapshot during scale up scenarios. So an old may exist.
  generate_pvcs
  kubectl scale statefulsets jira --replicas=$WANTED_REPLICAS
}

scale() {
  local CURRENT_REPLICAS=$(kubectl get statefulsets jira -o jsonpath="{.status.currentReplicas}")
  SCALE_VALUE=$(( (WANTED_REPLICAS - CURRENT_REPLICAS) )) # Set the GLOBAL SCALE_VALUE variable

  if ((CURRENT_REPLICAS == WANTED_REPLICAS)); then
    echo "Current number of replicas ($CURRENT_REPLICAS) matches wanted number of replicase ($WANTED_REPLICAS). Nothing to do..."
  elif ((CURRENT_REPLICAS > WANTED_REPLICAS)); then
    scale_down
  else
    scale_up
  fi
}

OPTIND=1
# Resetting OPTIND is necessary if getopts was used previously in the script.
# It is a good idea to make OPTIND local if you process options in a function.

while getopts :hn: opt; do
  case $opt in
    h)
      show_help
      exit 0
      ;;
    n)
      WANTED_REPLICAS=$OPTARG
      if [ "$WANTED_REPLICAS" == "" ]; then
        echo "You must specify the number of wanted replicas..."
        show_help
        exit 1
      fi
      scale
      ;;
    *)
      show_help
      exit 1
      ;;
  esac
done
shift "$((OPTIND-1))"   # Discard the options and sentinel --

# End of file