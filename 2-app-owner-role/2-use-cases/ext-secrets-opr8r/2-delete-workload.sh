#!/bin/bash

source ../../../demo-vars.sh

helm delete $APP_NAMESPACE_NAME -n $APP_NAMESPACE_NAME
kubectl delete -f ConjurSecretStore.yaml -n $APP_NAMESPACE_NAME
