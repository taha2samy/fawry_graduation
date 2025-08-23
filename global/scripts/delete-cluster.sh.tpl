kops delete cluster \
  --name "api.${cluster_name}" \
  --state "${bucket_name}/${state_store}/" \
  --yes