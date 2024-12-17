#!/bin/bash

source ../../demo-vars.sh

main() {
  instantiate_templates
  setup_workload_namespace
  create_app_identity
}

####################
# Substitute placeholders with values from demo-vars.sh
instantiate_templates() {
  mkdir -p ./policy
  templates=$(ls ./templates)
  for tmpl in $templates; do
    pfname=$(echo $tmpl | cut -d. -f1)
    cat ./templates/$tmpl						\
     | sed -e "s#{{JWT_SERVICE_ID}}#$JWT_SERVICE_ID#g"			\
     | sed -e "s#{{JWT_SERVICE_ACCOUNT}}#$JWT_SERVICE_ACCOUNT#g"	\
     | sed -e "s#{{APP_NAMESPACE_NAME}}#$APP_NAMESPACE_NAME#g"		\
     | sed -e "s#{{SAFE_NAME}}#$SAFE_NAME#g"				\
     > ./policy/$pfname.yaml
  done
}

####################
# Create app namespace, copies Conjur golden config map, creates service account
setup_workload_namespace() {
  echo
  echo "Creating namespace $APP_NAMESPACE_NAME..."
  kubectl delete ns $APP_NAMESPACE_NAME 2> /dev/null
  helm install namespace-prep --insecure-skip-tls-verify cyberark/conjur-config-namespace-prep \
    --create-namespace \
    --namespace $APP_NAMESPACE_NAME \
    --set conjurConfigMap.authnMethod="authn-jwt" \
    --set authnK8s.goldenConfigMap="conjur-configmap" \
    --set authnK8s.namespace="cyberark-conjur-jwt" \
    --set authnRoleBinding.create="false"

  kubectl create sa $JWT_SERVICE_ACCOUNT -n $APP_NAMESPACE_NAME
}

####################
# create app identity and grants access to secrets from safe
create_app_identity() {
  echo
  echo "Appending app identity policy to cluster workloads branch..."
    ../../bin/ccloud-cli.sh append data/$JWT_SERVICE_ID ./policy/app-identity-policy.yaml
  echo
  echo "Appending workload secrets access policy to /data/$JWT_SERVICE_ID branch..."
    ../../bin/ccloud-cli.sh append data ./policy/apps-secrets-grant-policy.yaml
  echo
}

main "$@"
