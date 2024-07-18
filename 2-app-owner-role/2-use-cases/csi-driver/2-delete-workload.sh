#!/bin/bash

source ../../../demo-vars.sh

kubectl delete -f ./app-manifest.yaml -n $APP_NAMESPACE_NAME
kubectl delete -f ./db-credentials.yaml -n $APP_NAMESPACE_NAME
# forced deletion of the pod is necessary for some reason
POD_NAME=$(kubectl get pods -n $APP_NAMESPACE_NAME --no-headers | grep csi | awk '{print $1}')
kubectl delete pod $POD_NAME -n $APP_NAMESPACE_NAME --force
