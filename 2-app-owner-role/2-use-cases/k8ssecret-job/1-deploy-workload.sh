#!/bin/bash

source ../../../demo-vars.sh

main() {
  instantiate_templates
  kubectl create -f ./provider-role-manifest.yaml -n $APP_NAMESPACE_NAME
  kubectl create -f ./db-credentials.yaml -n $APP_NAMESPACE_NAME
  kubectl apply -f ./k8s-provider-job.yaml -n $APP_NAMESPACE_NAME
  echo "Waiting for Secrets Provider job to complete"
  JOB_NAME=""
  until [[ "$JOB_NAME" != "" ]]; do
    echo -n "."
    sleep 1
    JOB_NAME=$(kubectl get pods -n $APP_NAMESPACE_NAME | grep secrets-provider | grep Running | awk '{print $1}')
  done
  kubectl logs $JOB_NAME -n $APP_NAMESPACE_NAME -f
  echo
  kubectl apply -f ./app-manifest.yaml -n $APP_NAMESPACE_NAME
  sleep 2
  echo
  echo "Run the script: ./mysql_k8s_secrets.sh"
  ./exec-into-pod.sh
}

####################
# Substitute placeholders with values from demo-vars.sh
instantiate_templates() {
  templates=$(ls ./templates)
  for tmpl in $templates; do
    fname=$(echo $tmpl | cut -d. -f1)
    cat ./templates/$tmpl                                               \
     | sed -e "s#{{CONJUR_URL}}#$CONJUR_URL#g"                          \
     | sed -e "s#{{JWT_SERVICE_ID}}#$JWT_SERVICE_ID#g"                  \
     | sed -e "s#{{JWT_SERVICE_ACCOUNT}}#$JWT_SERVICE_ACCOUNT#g"        \
     | sed -e "s#{{APP_NAMESPACE_NAME}}#$APP_NAMESPACE_NAME#g"          \
     | sed -e "s#{{APP_IMAGE}}#$APP_IMAGE#g"                            \
     | sed -e "s#{{SAFE_NAME}}#$SAFE_NAME#g"                            \
     | sed -e "s#{{MYSQL_ACCOUNT_NAME}}#$MYSQL_ACCOUNT_NAME#g"          \
     > ./$fname.yaml
  done
}

main "$@"
