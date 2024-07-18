#!/bin/bash

source ../../../demo-vars.sh

kubectl delete -f ./app-manifest.yaml -n $APP_NAMESPACE_NAME
kubectl delete -f ./db-credentials.yaml -n $APP_NAMESPACE_NAME
kubectl delete -f ./k8s-provider-job.yaml -n $APP_NAMESPACE_NAME
kubectl delete -f ./provider-role-manifest.yaml -n $APP_NAMESPACE_NAME
kubectl get all -n $APP_NAMESPACE_NAME
