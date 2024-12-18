# Edit this file substituting correct values for '<<YOUR_VALUE_HERE>>'

##################################################
# CyberArk tenant values

# Your CyberArk tenant subdomain name
#
#    https://your-subdomain.cyberark.cloud
# this value ^^^^^^^^^^^^^^

export CYBERARK_SUBDOMAIN_NAME=cybr-secrets

# check if subdomain set to non-placeholder value
if [[ "$CYBERARK_SUBDOMAIN_NAME" == '<<YOUR_VALUE_HERE>>' ]]; then
  echo "CYBERARK_SUBDOMAIN_NAME must be set in demo-vars.sh"
  return
fi

##################################################
# Configurable parameters
# These can be changed as needed. The values will be
# used in scripts and deployment manifests.

# Local container management - only docker is supported
export DOCKER="docker"

# Safe and account to be created in Privilege Cloud
export SAFE_NAME=K8sxlr8r
export MYSQL_ACCOUNT_NAME=K8s-MySQL

# The app namespace name is also used for the Conjur base policy ID.
# In effect, the base policy is the app namespace in Conjur.
export APP_NAMESPACE_NAME=k8sxlr8r

# Name of image for demo app - see subdirectory ./2-app-owner/0-build
export APP_IMAGE=k8s-app:alpine

# Namespace for target MySQL database
export DB_NAMESPACE_NAME=mysql

# authn-jwt ID scoped to K8s cluster
# Design note: An authn-jwt endpoint should correspond to,
# and be named for, the execution environment hosting
# its JWKS endpoint (K8s cluster, Jenkins controller, SaaS tenant, etc.).
export JWT_SERVICE_ID=k8s-cluster

# K8s service account identity for use-cases
export JWT_SERVICE_ACCOUNT=conjur-workload

# An optional, additional CyberArk user to add 
# as an admin to the Safe that will be created.
# User must exist. If none, leave as is.
export HUMAN_ADMIN_USER=""

#####################################################
#####################################################
# The values below should not need to be changed.
# Do so at your own risk!!!
#####################################################
#####################################################

######################
# K8s cluster parameters
export PLATFORM=kubernetes
export CLI=kubectl
export KUBECONFIG=~/.kube/config
export CLUSTER_ADMIN=foo			# OpenShift only
export CYBERARK_NAMESPACE_ADMIN=bar		# OpenShift only

######################
# More authn-jwt parameters

# Identity path is cluster base policy
export JWT_IDENTITY_PATH="data/$JWT_SERVICE_ID"
# 'sub' value will have format: 'system:serviceaccount:<namespace>:<service-acct-name>'
export JWT_TOKEN_APP_PROPERTY="sub"
# 'aud' claim is set with projected volume definition in deployment manifests
export JWT_AUDIENCE="conjur"

######################
# Image for CyberArk K8s Secrets Provider - automatically pulled from Dockerhub
export SECRETS_PROVIDER_IMAGE=cyberark/secrets-provider-for-k8s:latest

######################
# Portability stuff
# On Linux, use wrap arg=0 for encoding, lower case -d for decoding
if [[ "$(uname -s)" == "Linux" ]]; then
  BASE64E="base64 --wrap=0"
  BASE64D="base64 -d"
else
  BASE64E="base64"
  BASE64D="base64 -D"
fi

###########################################################
# MySQL database server parameters

export MYSQL_IMAGE=mysql:8.2.0
export MYSQL_CONTAINER=mysql-xlr8r
export MYSQL_ROOT_PASSWORD=In1t1alR00tPa55w0rd

# MySQL account properties - will be created and be synced to Conjur
export MYSQL_PLATFORM_NAME=MySQL
export MYSQL_SERVER_ADDRESS=mysql-db.$DB_NAMESPACE_NAME.svc.cluster.local
export MYSQL_SERVER_PORT=3306
export MYSQL_USERNAME=test_user1
export MYSQL_PASSWORD=UHGMLk1
export MYSQL_DBNAME=petclinic

# MySQL variable IDs in Conjur
# These are the names of secrets all deployments will retrieve to connect
# to the MySQL target database.
export MYSQL_ACCESS_ROLE=data/vault/$SAFE_NAME/delegation/consumers
export MYSQL_LOGIN_USER_ID=data/vault/$SAFE_NAME/$MYSQL_ACCOUNT_NAME/username
export MYSQL_PASSWORD_ID=data/vault/$SAFE_NAME/$MYSQL_ACCOUNT_NAME/password
export MYSQL_LOGIN_HOST_ID=data/vault/$SAFE_NAME/$MYSQL_ACCOUNT_NAME/address
export MYSQL_LOGIN_PORT_ID=data/vault/$SAFE_NAME/$MYSQL_ACCOUNT_NAME/Port

###########################################################
# Prompt for admin user name if not already set
if [[ "$CYBERARK_ADMIN_USER" == "" ]]; then
  clear
  echo "A CyberArk admin user is needed for demo setup & initialization."
  echo "The admin user must be a Service user & Oauth2 confidential client" 
  echo "in CyberArk Identity and must be granted the Conjur Admin role"
  echo "and minimally the Privilege Cloud Safe Managers Basic role."
  echo
  echo -n "Please enter the name of the service user: "
  read admin_user
  export CYBERARK_ADMIN_USER=$admin_user
fi

# Prompt for admin password if not already set
if [[ "$CYBERARK_ADMIN_PWD" == "" ]]; then
  echo -n "Please enter password for $CYBERARK_ADMIN_USER: "
  unset password
  while IFS= read -r -s -n1 pass; do
    if [[ -z $pass ]]; then
       echo
       break
    else
       echo -n '*'
       password+=$pass
    fi
  done
  export CYBERARK_ADMIN_PWD=$password
fi

###########################################################
export IDENTITY_TENANT_URL=https://$CYBERARK_SUBDOMAIN_NAME.cyberark.cloud/api/idadmin

export CONJUR_CLOUD_HOST=$CYBERARK_SUBDOMAIN_NAME.secretsmgr.cyberark.cloud
export CONJUR_CLOUD_URL=https://$CONJUR_CLOUD_HOST/api

# The demo defaults to use Conjur Cloud.
# Conjur Edge is an option. If you want to use Conjur Edge
# set CONJUR_HOST and CONJUR_URL variables below to 
# CONJUR_EDGE_HOST and CONJUR_EDGE_URL respectively.
export CONJUR_EDGE_HOST=ip-10-0-8-125
export CONJUR_EDGE_URL=https://$CONJUR_EDGE_HOST/api

# Edge K8s URL is for calling a local Edge node in Docker
# from a K8s cluster on the same host when using the
# hostname does not work.
export CONJUR_EDGE_K8S_URL=https://host.docker.internal/api

# Since Conjur Cloud & Edge are practically interchangeable,
# these details are abstracted with CONJUR_HOST & CONJUR_URL
# All K8s scripts and manifests use the abstract vars.
export CONJUR_HOST=$CONJUR_CLOUD_HOST
export CONJUR_URL=$CONJUR_CLOUD_URL

export CONJUR_ADMIN_USER=$CYBERARK_ADMIN_USER
export CONJUR_ADMIN_PWD=$CYBERARK_ADMIN_PWD

export PCLOUD_URL=https://$CYBERARK_SUBDOMAIN_NAME.privilegecloud.cyberark.cloud/PasswordVault/api
export PCLOUD_ADMIN_USER=$CYBERARK_ADMIN_USER
export PCLOUD_ADMIN_PWD=$CYBERARK_ADMIN_PWD

##########################################################
# END
