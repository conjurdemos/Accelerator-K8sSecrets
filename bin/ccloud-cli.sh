#!/bin/bash

####################################################
# ccloud-cli.sh - a bash script CLI for Conjur Cloud
####################################################

# With Conjur Cloud & Edge nodes w/ custom CA-rooted certs, neither the server cert nor the -k flag are required.
# With Conjur Cloud Edge nodes w/ auto-generated certs, either the edge cert or the -k flag is required.
# use 'curl -v' and 'set -x' for verbose debugging 
export CURL="curl -sk"
util_defaults="set -u"

showUsage() {
  echo "Usage:"
  echo "      $0 [ whoami | resources | list | listws | listvars ]"
  echo "      $0 [ get <var-name> ]"
  echo "      $0 [ set <var-name> <var-value> ]"
  echo "      $0 [ append <policy-branch> <policy-file-name> ]"
  echo "      $0 [ update <policy-branch> <policy-file-name> ]"
  echo "      $0 [ enable <authn-type> <service-id> ]"
  echo "      $0 [ status <authn-type> <service-id> ]"
  echo "      $0 [ rotate <workload-id> ]"
  exit -1
}

main() {
  checkDependencies

  if [[ $0 == *ccedge-cli.sh ]]; then
    CONJUR_CLOUD_URL=$CONJUR_EDGE_URL
  fi

  case $1 in
    whoami | resources | list | listws | listvars)
	command=$1
	;;
    get)
	if [[ $# != 2 ]]; then
	  showUsage
	fi
	command=$1
	varName=$2
	;;
    set)
	if [[ $# != 3 ]]; then
	  showUsage
	fi
	command=$1
	varName=$2
	varValue="$3"
	;;
    append | update)
	if [[ $# != 3 ]]; then
	  showUsage
	fi
	command=$1
	policyBranch=$2
	policyFilename=$3
	;;
    enable)
	if [[ $# != 3 ]]; then
	  showUsage
	fi
	command=$1
	authnType=$2
	serviceId=$3
	;;
    status)
	if [[ $# != 3 ]]; then
	  showUsage
	fi
	command=$1
	authnType=$2
	serviceId=$3
	;;
    rotate)
	if [[ $# != 2 ]]; then
	  showUsage
	fi
	command=$1
	workloadId=$2
	;;
    *)
	showUsage
	;;
  esac

  conjur_authenticate	# sets global variable authHeader

  case $command in
    whoami)
	conjur_whoami
	;; 
    resources)
	conjur_resources 
	;;
    list)
	conjur_list 
	;;
    listws)
	conjur_list_webservices
	;;
    listvars)
	conjur_list_variables
	;;
    get)
	conjur_get_variable $varName
	;;
    set)
	conjur_set_variable $varName "$varValue"
	;;
    append)
	conjur_append_policy $policyBranch $policyFilename
	;;
    update)
	conjur_update_policy $policyBranch $policyFilename
	;;
    enable)
	conjur_authn_enable $authnType $serviceId
	;;
    status)
	conjur_authn_status $authnType $serviceId
	;;
    rotate)
	conjur_rotate_workload_api_key $workloadId
	;;

	# apparently these functions are not implemented in Conjur Cloud
    info)
	conjur_info
	;; 
    health)
	conjur_health
	;; 
    audit)
	conjur_audit 
	;;
    *)
	showUsage
	;;
  esac

  exit 0


}

#####################################
# sets the global authorization header used in api calls for other methods
function conjur_authenticate {
  $util_defaults
  jwToken=$($CURL \
        -X POST \
        $IDENTITY_TENANT_URL/oauth2/platformtoken 			\
        -H "Content-Type: application/x-www-form-urlencoded"      	\
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CONJUR_ADMIN_USER"               \
        --data-urlencode "client_secret"="$CONJUR_ADMIN_PWD"		\
	| jq -r .access_token)
  if [[ "$jwToken" == "" ]]; then
    echo "Error authenticating. Check subdomain and admin user credentials set in demo-vars.sh."
    exit -1
  fi
  authToken=$($CURL	\
        -X POST		\
	$CONJUR_CLOUD_URL/authn-oidc/cyberark/conjur/authenticate 	\
	-H "Content-Type: application/x-www-form-urlencoded"		\
	-H "Accept-Encoding: base64"					\
	--data-urlencode "id_token=$jwToken" )
  authHeader="Authorization: Token token=\"$authToken\""
}

#####################################
function conjur_whoami {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CONJUR_CLOUD_URL}/whoami"
}

#####################################
function conjur_resources {
  $util_defaults
  echo "Returning first 1000 resource entries."
  $CURL 						\
	-X GET						\
	-H "$authHeader" 				\
	"$CONJUR_CLOUD_URL/resources/conjur" | jq .
}

#####################################
function conjur_list {
  $util_defaults
  resources=$(conjur_resources)
  echo "${resources}" | jq -r .[].id
}

#####################################
function conjur_list_variables {
  $util_defaults
  $CURL 						\
	-X GET						\
	-H "$authHeader" 				\
	"$CONJUR_CLOUD_URL/resources/conjur?kind=variable" | jq -r .[].id
}

#####################################
function conjur_list_webservices {
  $util_defaults
  $CURL 						\
	-X GET						\
	-H "$authHeader" 				\
	"$CONJUR_CLOUD_URL/resources/conjur?kind=webservice" | jq -r .[].id
}

#####################################
function conjur_get_variable {
  $util_defaults
  varName=$1
  var=$(urlify $varName)
  value=$($CURL							\
	  -X GET 						\
	  $CONJUR_CLOUD_URL/secrets/conjur/variable/$var	\
          -H "Content-Type: application/json"			\
	  -H "$authHeader")
  echo -n "${value}"
}

#####################################
function conjur_set_variable {
  $util_defaults
  variable_name=$1
  variable_value="$2"
  $CURL					\
  	-H "$authHeader"		\
	--data "$variable_value"	\
	"$CONJUR_CLOUD_URL/secrets/conjur/variable/$variable_name"
}

#####################################
function conjur_append_policy {
  $util_defaults
  policy_branch=$1
  policy_name=$2
#  response=$(
$CURL			\
	-X POST				\
  	-H "$authHeader"		\
	-d "$(< $policy_name)"		\
	$CONJUR_CLOUD_URL/policies/conjur/policy/$policy_branch
#)
#  echo "$response"
}

#####################################
function conjur_update_policy {
  $util_defaults
  policy_branch=$1
  policy_name=$2
  response=$($CURL				\
	-X PATCH				\
  	-H "$authHeader"			\
	-d "$(< $policy_name)"			\
	$CONJUR_CLOUD_URL/policies/conjur/policy/$policy_branch)
  echo "$response"
}

#####################################
function conjur_authn_enable {
  $util_defaults
  authnType=$1; shift
  serviceId=$1; shift
  response=$($CURL						\
  	-X PATCH 						\
  	-H "$authHeader" 					\
	--data-raw "enabled=true"				\
	"${CONJUR_CLOUD_URL}/${authnType}/${serviceId}/conjur")
  echo "$response"
}

#####################################
function conjur_authn_status {
  $util_defaults
  authnType=$1; shift
  serviceId=$1; shift
  response=$($CURL						\
        -X GET							\
        -H "$authHeader"                                        \
        "${CONJUR_CLOUD_URL}/${authnType}/${serviceId}/conjur/status")
  echo "$response"
}

#####################################
function conjur_rotate_workload_api_key {
	local id=$1; shift
	$util_defaults
	api_key=$($CURL						\
		-X PUT						\
		-H "$authHeader"				\
		"$CONJUR_CLOUD_URL/authn/conjur/api_key?role=host:${id}")
	echo $api_key
}

#####################################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: encoded string on stdout
function urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        str=$(echo $str | sed 's=+=%2B=g')
        str=$(echo $str | sed 's=&=%26=g')
        str=$(echo $str | sed 's=@=%40=g')
        echo $str
}

#####################################
# verifies jq installed & required environment variables are set
function checkDependencies() {
  all_env_set=true
  if [[ "$(which jq)" == "" ]]; then
    echo
    echo "The JSON query utility jq is required. Please install jq."
    all_env_set=false
  fi
  if [[ "$IDENTITY_TENANT_URL" == "" ]]; then
    echo
    echo "  IDENTITY_TENANT_URL must be set - e.g. 'https://my-secrets.cyberark.cloud/api/idadmin'"
    all_env_set=false
  fi
  if [[ "$CONJUR_CLOUD_URL" == "" ]]; then
    echo
    echo "  CONJUR_CLOUD_URL must be set - e.g. 'https://my-secrets.secretsmgr.cyberark.cloud/api'"
    echo "    (and dont forget the /api)"
    all_env_set=false
  fi
  if [[ "$CONJUR_EDGE_URL" == "" ]]; then
    echo
    echo "  CONJUR_CLOUD_URL must be set - e.g. 'https://my-edge-node-host/api'"
    echo "    (and dont forget the /api)"
    all_env_set=false
  fi
  if [[ "$CONJUR_ADMIN_USER" == "" ]]; then
    echo
    echo "  CONJUR_ADMIN_USER must be set - e.g. foo_bar@cyberark.cloud.7890"
    echo "    This MUST be a Service User and Oauth confidential client."
    echo "    This script will not work for human user identities."
    all_env_set=false
  fi
  if [[ "$CONJUR_ADMIN_PWD" == "" ]]; then
    echo
    echo "  CONJUR_ADMIN_PWD must be set to the CONJUR_ADMIN_USER password."
    all_env_set=false
  fi
  if ! $all_env_set; then
    echo
    exit -1
  fi
}

main "$@"
