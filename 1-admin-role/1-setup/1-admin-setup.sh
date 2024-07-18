#!/bin/bash

source ../../demo-vars.sh

main() {
  instantiate_templates
  setup_cluster_authn_endpoint
  setup_cluster_workload_policy
  create_golden_configmap
  create_db_secrets_in_vault
}

####################
# Substitute placeholders with values from demo-vars.sh
instantiate_templates() {
  mkdir -p ./policy
  templates=$(ls ./templates)
  for tmpl in $templates; do
    pfname=$(echo $tmpl | cut -d. -f1)
    cat ./templates/$tmpl                                               \
     | sed -e "s#{{JWT_SERVICE_ID}}#$JWT_SERVICE_ID#g"                  \
     > ./policy/$pfname.yaml
  done
}

####################
# setup_cluster_authn_endpoint()
#
# This function creates a Conjur authn-jwt endpoint for a K8s cluster.
# It uses kubectl to extract JWKS info from the K8s cluster
# and caches the keys in the policy's pubkeys variable.

setup_cluster_authn_endpoint() {
  echo
  echo "Getting cluster JWT variable values..."

    # In Docker Desktop K8s JWTs, audience claims are an array with the issuer as element
    JWT_ISSUER="$(kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer')"

    # Docker Desktop K8s JWKS is not accessible (at least on CyberArk Macs)
    kubectl get --raw $(kubectl get --raw /.well-known/openid-configuration | jq -r '.jwks_uri') > jwks.json
    JWT_PUBKEYS="{\"type\":\"jwks\", \"value\":$(cat jwks.json)}"
    rm jwks.json

  echo "Loading authn-jwt policy..."
    cat ./templates/authn-jwt-policy.template.yaml	\
    | sed -e "s#{{JWT_SERVICE_ID}}#$JWT_SERVICE_ID#g"	\
    > ./authn-jwt-$JWT_SERVICE_ID-policy.yaml
    ../../bin/ccloud-cli.sh append /conjur/authn-jwt ./authn-jwt-$JWT_SERVICE_ID-policy.yaml

  echo
  echo "Setting authn-jwt variable values..."
    ../../bin/ccloud-cli.sh set conjur/authn-jwt/$JWT_SERVICE_ID/public-keys "$JWT_PUBKEYS"
    ../../bin/ccloud-cli.sh set conjur/authn-jwt/$JWT_SERVICE_ID/issuer "$JWT_ISSUER"
    ../../bin/ccloud-cli.sh set conjur/authn-jwt/$JWT_SERVICE_ID/token-app-property "$JWT_TOKEN_APP_PROPERTY"
    ../../bin/ccloud-cli.sh set conjur/authn-jwt/$JWT_SERVICE_ID/identity-path "$JWT_IDENTITY_PATH"
    ../../bin/ccloud-cli.sh set conjur/authn-jwt/$JWT_SERVICE_ID/audience "$JWT_AUDIENCE"

  echo "Enabling authn-jwt endpoint..."
    ../../bin/ccloud-cli.sh enable authn-jwt $JWT_SERVICE_ID

  echo "Checking status of authn-jwt endpoint..."
    ../../bin/ccloud-cli.sh status authn-jwt $JWT_SERVICE_ID
}

####################
# Create Conjur base policy for cluster workloads and
# give its group permission to authenticate to the authn-jwt endpoint
# for the cluster.
setup_cluster_workload_policy() {
  echo
  echo "Appending cluster base policy to /data..."
    ../../bin/ccloud-cli.sh append data ./policy/app-base-policy.yaml

  echo
  echo "Appending cluster workload authentication policy to /conjur/authn-jwt branch..."
    ../../bin/ccloud-cli.sh append conjur/authn-jwt ./policy/apps-authn-grant-policy.yaml
}

####################
create_golden_configmap() {
  helm repo add cyberark https://cyberark.github.io/helm-charts 2> /dev/null
  helm repo update

  # delete namespace to suppress helm "already exists" errors
  kubectl delete ns cyberark-conjur-jwt 2> /dev/null

  CONJUR_CERT="$(openssl s_client -connect $CONJUR_HOST:443 -showcerts </dev/null 2>/dev/null   \
  | openssl x509 -in /dev/stdin -outform PEM)"
  # It is super important to always quote cert variables to preserve newline formatting
  b64cert=$(echo "$CONJUR_CERT" | $BASE64E)
  helm install "cluster-prep" cyberark/conjur-config-cluster-prep	\
      -n "cyberark-conjur-jwt"						\
      --create-namespace						\
      --set conjur.account="conjur"					\
      --set conjur.applianceUrl="$CONJUR_URL"				\
      --set conjur.certificateBase64="$b64cert"				\
      --set authnK8s.authenticatorID="$JWT_SERVICE_ID"			\
      --set authnK8s.clusterRole.create=false				\
      --set authnK8s.serviceAccount.create=false
}

####################
create_db_secrets_in_vault() {
  ../../bin/cybrvault-cli.sh safe_create $SAFE_NAME "Safe for K8s accelerator"
  ../../bin/cybrvault-cli.sh safe_sync_add $SAFE_NAME "Conjur Sync"
  ../../bin/cybrvault-cli.sh account_create_db $SAFE_NAME "$MYSQL_PLATFORM_NAME" 		\
				"$MYSQL_ACCOUNT_NAME" "$MYSQL_USERNAME" "$MYSQL_PASSWORD"	\
				"$MYSQL_SERVER_ADDRESS" "$MYSQL_DBNAME" "$MYSQL_SERVER_PORT"
  if [[ "$HUMAN_ADMIN_USER" != "" ]]; then
    ../../bin/cybrvault-cli.sh safe_admin_add $SAFE_NAME $HUMAN_ADMIN_USER
  fi
}

main "$@"

