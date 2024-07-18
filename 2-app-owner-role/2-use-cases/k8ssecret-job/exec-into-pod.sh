#!/bin/bash

source ../../../demo-vars.sh

POD_NAME=$(kubectl get pods -n $APP_NAMESPACE_NAME --no-headers | grep Running | grep app-example-k8s-job | awk '{print $1}')
kubectl exec -it $POD_NAME -n $APP_NAMESPACE_NAME -c test-app -- bash
