#!/bin/bash

source ../../../demo-vars.sh

kubectl delete -f app-manifest.yaml -n $APP_NAMESPACE_NAME --ignore-not-found
kubectl delete -f app-config-map.yaml -n $APP_NAMESPACE_NAME --ignore-not-found
kubectl get pods -n $APP_NAMESPACE_NAME
