#!/bin/bash

source ../../../demo-vars.sh

main() {
  instantiate_templates
  kubectl apply -f provider-role-manifest.yaml
  kubectl create -f app-manifest.yaml -n $APP_NAMESPACE_NAME
  sleep 2
  POD_NAME=$(kubectl get pods -n $APP_NAMESPACE_NAME --no-headers | grep app-example-file-init | awk '{print $1}')
  kubectl logs $POD_NAME -n $APP_NAMESPACE_NAME -c secrets-provider -f
  wait_until_ready
  echo
  echo "Run the script: ./mysql_file.sh"
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

####################
wait_until_ready() {
  POD_NAME=""
  until [[ "$POD_NAME" != "" ]]; do
    sleep 1
    POD_NAME=$(kubectl get pods -n $APP_NAMESPACE_NAME --no-headers | grep Running | grep app-example-file-init | awk '{print $1}')
  done
}

main"$@"
