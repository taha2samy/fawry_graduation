#!/bin/bash

kops export kubeconfig \
  --name "${cluster_name}" \
  --state "${kops_state}" \
  --admin \
  --kubeconfig ./kubeconfig/kubeconfig-original.yaml

cp ./kubeconfig/kubeconfig-original.yaml ./kubeconfig/kubeconfig-tunneled.yaml
yq -i '(.clusters[] | select(.name == "api.internal.fawry.example.com").cluster.server) = "https://127.0.0.1:8443"' ./kubeconfig/kubeconfig-tunneled.yaml
