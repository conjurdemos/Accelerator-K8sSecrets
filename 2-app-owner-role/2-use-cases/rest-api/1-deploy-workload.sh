#!/bin/bash

source ../../../demo-vars.sh

main() {
  instantiate_templates

  kubectl create -f app-config-map.yaml -n $APP_NAMESPACE_NAME
  kubectl create -f app-manifest.yaml -n $APP_NAMESPACE_NAME
  sleep 2
  kubectl get pods -n $APP_NAMESPACE_NAME
  sleep 1
  echo
  echo "Run the script: mysql_REST.sh"
  ./exec-into-pod.sh
}

####################
# Substitute placeholders with values from demo-vars.sh
instantiate_templates() {
  templates=$(ls ./templates)
  for tmpl in $templates; do
    fname=$(echo $tmpl | cut -d. -f1)
    cat ./templates/$tmpl                                               \
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
