#!/bin/bash

kops export kubeconfig \
  --name "${cluster_name}" \
  --state "${kops_state}" \
  --admin \
  --kubeconfig ./kubeconfig-original.yaml

cp ./kubeconfig-original.yaml ./kubeconfig-tunneled.yaml
yq -i '(.clusters[] | select(.name == "api.internal.fawry.example.com").cluster.server) = "https://127.0.0.1:8443"' ./kubeconfig-tunneled.yaml
#export KUBECONFIG=$(pwd)/kubeconfig-tunneled.yaml
#export KUBECONFIG=$(pwd)/kubeconfig-original.yaml
