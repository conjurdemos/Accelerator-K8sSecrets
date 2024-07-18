#!/bin/bash
# This script deletes all changes made to Pcloud and Conjur Cloud 
# for the K8sSecrets accelerator.

source ../demo-vars.sh

# DB namespace
echo "Deleting $DB_NAMESPACE_NAME namespace in K8s..."
kubectl delete ns $DB_NAMESPACE_NAME

# App namespace
echo "Deleting $APP_NAMESPACE_NAME namespace in K8s..."
kubectl delete ns $APP_NAMESPACE_NAME

# GoldenConfigmap namespace
echo "Deleting cyberark-conjur-jwt namespace in K8s..."
kubectl delete ns cyberark-conjur-jwt

# authn-jwt authenticator
echo "Deleting authn-jwt/$JWT_SERVICE_ID authenticator endpoint in Conjur..."
cat templates/delete-authn-jwt.template.yml		\
  | sed -e "s#{{JWT_SERVICE_ID}}#$JWT_SERVICE_ID#g"	\
  > policy/delete-authn-jwt.yml
../bin/ccloud-cli.sh update /conjur/authn-jwt ./policy/delete-authn-jwt.yml

# app policy branch
echo "Deleting application policy in Conjur..."
cat templates/delete-app-branch.template.yml			\
  | sed -e "s#{{APP_NAMESPACE_NAME}}#$APP_NAMESPACE_NAME#g"	\
  > policy/delete-app-branch.yml
../bin/ccloud-cli.sh update /data ./policy/delete-app-branch.yml

# Account in Pcloud
echo "Deleting account $MYSQL_ACCOUNT_NAME in safe $SAFE_NAME in Privilege Cloud..."
../bin/cybrvault-cli.sh account_delete $SAFE_NAME $MYSQL_ACCOUNT_NAME

# Safe in Pcloud
echo "Deleting safe $SAFE_NAME in Privilege Cloud..."
../bin/cybrvault-cli.sh safe_delete $SAFE_NAME

exit

#########################################
# Deleting groups and variables in Conjur
# somehow disables syncing from a safe
# with the same name, preventing reuse
# of safe names. So for now, we are not
# deleting groups and variables for synced safes.

# Safe groups in Conjur Cloud
echo "Deleting $SAFE_NAME groups in Conjur Cloud..."
cat templates/delete-safe-groups.template.yml			\
  | sed -e "s#{{SAFE_NAME}}#$SAFE_NAME#g"	\
  > policy/delete-safe-groups.yml
../bin/ccloud-cli.sh update data/vault policy/delete-safe-groups.yml

# Secrets in Conjur Cloud
echo "Deleting $SAFE_NAME secrets in Conjur Cloud..."
policy_file="policy/delete-safe-vars.yml"
vars=$(../bin/ccloud-cli.sh listvars | grep data/vault/$SAFE_NAME | grep $MYSQL_ACCOUNT_NAME)
echo "# delete-safe-vars.yml" > $policy_file
echo "# applied at /data/vault" >> $policy_file
for var in $vars; do
  var_name=$(echo $var | cut -d: -f3 | cut -d/ -f3-)
  echo $var_name
  echo "- !delete" >> $policy_file
  echo "  record: !variable" $var_name >> $policy_file
done
../bin/ccloud-cli.sh update data/vault $policy_file
