#!/bin/bash

source ../../../demo-vars.sh

POD_NAME=$(kubectl get pods -n $APP_NAMESPACE_NAME --no-headers | grep Running | grep app-example-restapi | awk '{print $1}')
if [[ "$POD_NAME" == "" ]]; then
  echo "No running pod named 'app-example-restapi-*' found in namespace $APP_NAMESPACE_NAME."
  exit -1
fi
kubectl exec -it $POD_NAME -n $APP_NAMESPACE_NAME -- bash
