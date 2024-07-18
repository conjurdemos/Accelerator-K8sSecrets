#!/bin/bash

source ../../../demo-vars.sh

set -uo pipefail

main() {
  instantiate_templates
  kubectl apply -f ConjurSecretStore.yaml -n $APP_NAMESPACE_NAME
  helm install $APP_NAMESPACE_NAME ./charts/app -n $APP_NAMESPACE_NAME --set namespace=$APP_NAMESPACE_NAME --debug
  sleep 1
  ../../../bin/get-info.sh r $APP_NAMESPACE_NAME
  sleep 2
  echo
  echo "Run the script: ./mysql_k8s_secrets.sh"
  ./exec-into-pod.sh
}

####################
# Substitute placeholders with values from demo-vars.sh
# For Helm, we are instantiating values in the chart values.yaml
# then moving the instantiated file to its correct location.
instantiate_templates() {
  CONJUR_CERT="$(openssl s_client -connect $CONJUR_HOST:443 -showcerts </dev/null 2>/dev/null	\
  | openssl x509 -in /dev/stdin -outform PEM)"
  b64cert=$(echo "$CONJUR_CERT" | $BASE64E)
  templates=$(ls ./templates)
  for tmpl in $templates; do
    fname=$(echo $tmpl | cut -d. -f1)
    cat ./templates/$tmpl                                               \
     | sed -e "s#{{CONJUR_URL}}#$CONJUR_URL#g"                  	\
     | sed -e "s#{{CONJUR_CERT_B64}}#$b64cert#g"                  	\
     | sed -e "s#{{JWT_SERVICE_ID}}#$JWT_SERVICE_ID#g"                  \
     | sed -e "s#{{JWT_SERVICE_ACCOUNT}}#$JWT_SERVICE_ACCOUNT#g"        \
     | sed -e "s#{{APP_NAMESPACE_NAME}}#$APP_NAMESPACE_NAME#g"          \
     | sed -e "s#{{APP_IMAGE}}#$APP_IMAGE#g"                            \
     | sed -e "s#{{SAFE_NAME}}#$SAFE_NAME#g"                            \
     | sed -e "s#{{MYSQL_ACCOUNT_NAME}}#$MYSQL_ACCOUNT_NAME#g"          \
     > ./$fname.yaml
  done
  mv values.yaml charts/app/values.yaml
}

main "$@"
