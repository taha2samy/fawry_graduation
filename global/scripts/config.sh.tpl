kops get cluster api.${cluster_name} --state=${bucket_name}/${state_store} -o yaml > kops/cluster.yaml
yq e '.spec.awsLoadBalancerController.enabled = true' -i kops/cluster.yaml
yq e '.spec.certManager.enabled = true' -i kops/cluster.yaml
