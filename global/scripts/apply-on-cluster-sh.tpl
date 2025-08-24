kops replace -f kops/cluster.yaml --state=${bucket_name}/${state_store}
kops update cluster api.${cluster_name} --state=${bucket_name}/${state_store} --yes
kops rolling-update cluster api.${cluster_name} --state=${bucket_name}/${state_store}  --yes
