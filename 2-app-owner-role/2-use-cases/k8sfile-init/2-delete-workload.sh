#!/bin/bash

source ../../../demo-vars.sh

kubectl delete -f app-manifest.yaml -n $APP_NAMESPACE_NAME
kubectl delete -f provider-role-manifest.yaml
kubectl get pods -n $APP_NAMESPACE_NAME
