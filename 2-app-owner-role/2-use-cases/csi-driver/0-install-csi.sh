#!/bin/bash

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store \
  secrets-store-csi-driver/secrets-store-csi-driver \
  --wait \
  --namespace kube-system \
  --set syncSecret.enabled="false" \
  --set 'tokenRequests[0].audience=conjur'

helm repo add cyberark https://cyberark.github.io/helm-charts
helm install conjur-csi-provider \
  cyberark/conjur-k8s-csi-provider \
  --wait \
  --namespace kube-system \
  --set daemonSet.image.tag="0.2.0" \
  --set provider.name="conjur" \
  --set provider.healthPort="8080" \
  --set provider.socketDir="/var/run/secrets-store-csi-providers"

echo
echo "CSI components deployed to the kube-system namespace:"
echo
echo "Waiting until all CSI deployments are ready before deploying workloads."
echo "This can take up to a few minutes."
echo
all_ready="xxx"
until [[ "$all_ready" == "" ]]; do
  sleep 1
  echo -n "."
  all_ready=$(kubectl get pods -n kube-system | grep csi | grep "0/")
done
echo
kubectl get pods -n kube-system | grep csi
