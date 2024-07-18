#!/bin/bash

main() {
  echo "This script assumes:"
  echo "- Docker Desktop is installed"
  echo "- Docker Desktop Kubernetes support is enabled"
  echo "- kubectl is installed and functional"
  verify_docker
  verify_kubectl
#  install_helm
}

########################
verify_docker() {
  dv=$($DOCKER --version)
  vrfy=$(echo $dv | grep "Docker version")
  if [[ "$vrfy" != "" ]]; then
    echo $dv
  else
    echo "Docker not found, please install Docker Desktop before proceeding."
    exit -1
  fi
}

########################
verify_kubectl() {
  kctxt=$(kubectl config use-context docker-desktop)
  vrfy=$(echo $kctxt | grep 'Switched to context "docker-desktop"')
  if [[ "$vrfy" != "" ]]; then
    echo -n "Kubectl "
    kubectl version
    echo $kctxt
  else
    echo "Kubectl or docker-desktop context not found, please enable Docker Desktop Kubernetes before proceeding."
    exit -1
  fi
}

########################
install_helm() {
  echo "Installing Helm..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  rm ./get_helm.sh
}

main "$@"
