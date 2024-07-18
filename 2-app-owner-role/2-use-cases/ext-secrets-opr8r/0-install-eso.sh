#!/bin/bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace
echo
echo
echo "You can use this command to check readiness status:"
echo "    kubectl get deployment -n external-secrets"
echo
echo "Wait until all ESO deployments are ready before deploying workloads."
echo "This can take 2-3 minutes."
echo
all_ready="xxx"
until [[ "$all_ready" == "" ]]; do
  sleep 1
  echo -n "."
  all_ready=$(kubectl get deployment -n external-secrets | grep "0/1")
done
echo
kubectl get deployment -n external-secrets
