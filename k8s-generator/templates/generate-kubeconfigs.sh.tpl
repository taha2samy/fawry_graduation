#!/bin/bash
set -e

kops export kubeconfig \
  --name "${cluster_name}" \
  --state "${kops_state}" \
  --admin \
  --kubeconfig ./kubeconfig-original.yaml

cp ./kubeconfig-original.yaml ./kubeconfig-tunneled.yaml

sed -i.bak "s|https://api.${cluster_name}|https://127.0.0.1:8443|g" ./kubeconfig-tunneled.yaml
