#!/bin/bash -e
source ../../demo-vars.sh

set -x
if [[ $(uname -o) == *Linux ]]; then
  # build in context of Minikube docker env
  eval $(minikube docker-env)
fi
$DOCKER build -t $APP_IMAGE .
$DOCKER system prune
