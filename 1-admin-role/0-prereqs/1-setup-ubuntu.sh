#!/bin/bash

main() {
  install_docker
  install_kubectl
  install_minikube
  install_helm
  echo
  echo
  echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
  echo "Log out and back in again before starting minikube."
  echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
  echo
}

########################
install_docker() {
  echo "Installing Docker..."
  sudo apt update
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  apt-cache policy docker-ce
  sudo apt install -y docker-ce
  sudo usermod -aG docker ${USER}
}

########################
install_kubectl() {
  echo "Installing Kubectl..."
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo snap install kubectl --classic
}

########################
install_minikube() {
  echo "Installing Minikube..."
  ARCH=$(uname -m)
  case $ARCH in
    x86_64)
        curl -LO -k https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        ;;
    aarch64)
        curl -LO -k https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
        sudo install minikube-linux-arm64 /usr/local/bin/minikube && rm minikube-linux-arm64
        ;;
    *)
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!! Unknown machine architecture. Cannot install minikube !!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        exit -1
  esac
  echo
  echo "Minikube installed"
  minikube version
  echo
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
