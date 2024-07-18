#!/bin/bash

source ../../../demo-vars.sh

main() {
  instantiate_templates
  kubectl apply -f ./db-credentials.yaml -n $APP_NAMESPACE_NAME
  kubectl apply -f ./app-manifest.yaml -n $APP_NAMESPACE_NAME
  sleep 1
  ../../../bin/get-info.sh r $APP_NAMESPACE_NAME
  sleep 1
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
     | sed -e "s#{{CONJUR_URL}}#$CONJUR_URL#g"        			\
     | sed -e "s#{{JWT_SERVICE_ID}}#$JWT_SERVICE_ID#g"                  \
     | sed -e "s#{{JWT_SERVICE_ACCOUNT}}#$JWT_SERVICE_ACCOUNT#g"        \
     | sed -e "s#{{APP_NAMESPACE_NAME}}#$APP_NAMESPACE_NAME#g"          \
     | sed -e "s#{{APP_IMAGE}}#$APP_IMAGE#g"                            \
     | sed -e "s#{{SAFE_NAME}}#$SAFE_NAME#g"                            \
     | sed -e "s#{{MYSQL_ACCOUNT_NAME}}#$MYSQL_ACCOUNT_NAME#g"          \
     > ./$fname.yaml
  done

  # add indented cert to db-credentials manifest
  CONJUR_CERT="$(openssl s_client -connect $CONJUR_HOST:443 -showcerts </dev/null 2>/dev/null	\
  | openssl x509 -in /dev/stdin -outform PEM)"
  echo -n "$CONJUR_CERT" \
  | awk '{ print "      " $0 }' > cert.indented
  # (see: https://stackoverflow.com/questions/6790631/use-the-contents-of-a-file-to-replace-a-string-using-sed)
  sed -e '/{{CONJUR_CERT}}/{
  		s/{{CONJUR_CERT}}//g
		r ./cert.indented
	}' ./db-credentials.yaml	\
  > ./tempx
  mv ./tempx ./db-credentials.yaml
  rm ./cert.indented
}

main "$@"
