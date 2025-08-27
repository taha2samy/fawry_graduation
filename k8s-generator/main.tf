data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "${path.root}/../global/terraform.tfstate"
  }
}

locals {
  private_subnet_ids = join(",", [
    for k, v in data.terraform_remote_state.network.outputs.k8s_subnets : v.id
  ])

  utility_subnet_ids = join(",", [
    for k, v in data.terraform_remote_state.network.outputs.k8s_utility_subnets : v.id
  ])
  
  availability_zones = join(",", distinct([
    for k, v in data.terraform_remote_state.network.outputs.k8s_subnets : v.availability_zone
  ]))

  s3_url = data.terraform_remote_state.network.outputs.s3_url
  cluster_name       = var.kops_cluster_name
  network_id         = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr           = data.terraform_remote_state.network.outputs.vpc_cidr_block
  zones              = local.availability_zones
  dns_zone_id        = data.terraform_remote_state.network.outputs.private_zone_id
  kops_state_store   = var.kops_state_store
}


resource "null_resource" "kops_generate_terraform" {
  triggers = {
    cluster_name     = local.cluster_name
    s3_url           = local.s3_url
    kops_state_store = local.kops_state_store
  } 
  provisioner "local-exec" {
    command = <<-EOT
      kops create cluster \
        --name=${local.cluster_name} \
        --state=${local.s3_url}/${local.kops_state_store} \
        --cloud=aws \
        --network-id=${local.network_id} \
        --network-cidr=${local.vpc_cidr} \
        --subnets=${local.private_subnet_ids} \
        --utility-subnets=${local.utility_subnet_ids} \
        --topology=private \
        --zones=${local.zones} \
        --control-plane-zones=${local.zones} \
        --dns=private \
        --dns-zone=${local.dns_zone_id} \
        --node-count=3 \
        --node-size=t3.medium \
        --control-plane-size=t3.medium \
        --networking=calico \
        --ssh-public-key=../ssh\ keys/public.pub \
        --out=../k8s \
        --yes
    EOT
  }
  provisioner "local-exec" {
    command = <<-EOT
    until kops validate cluster --name "${self.triggers.cluster_name}" --state "${self.triggers.s3_url}/${self.triggers.kops_state_store}" >/dev/null 2>&1; do
      echo "Waiting for cluster ${self.triggers.cluster_name} to be ready..."
      sleep 10
    done
      kops export kubeconfig \
        --name "${local.cluster_name}" \
        --state "${self.triggers.s3_url}/${self.triggers.kops_state_store}" \
        --admin \
        --kubeconfig ../kubeconfig/kubeconfig-original.yaml

      cp ../kubeconfig/kubeconfig-original.yaml ../kubeconfig/kubeconfig-tunneled.yaml
      yq -i '(.clusters[] | select(.name == "${local.cluster_name}").cluster.server) = "https://127.0.0.1:8443"' ../kubeconfig/kubeconfig-tunneled.yaml
      kops get cluster api.${local.cluster_name} --state="${self.triggers.s3_url}/${self.triggers.kops_state_store}" -o yaml > ../kops/cluster.yaml
      yq e '.spec.awsLoadBalancerController.enabled = true' -i ../kops/cluster.yaml
      yq e '.spec.certManager.enabled = true' -i ../kops/cluster.yaml
      kops replace -f ../kops/cluster.yaml --state="${self.triggers.s3_url}/${self.triggers.kops_state_store}"
      kops update cluster ${local.cluster_name} --state="${local.s3_url}/${local.kops_state_store}" --yes
      kops rolling-update cluster ${local.cluster_name} --state="${local.s3_url}/${local.kops_state_store}"  --yes
    EOT
  }
  provisioner "local-exec" {
  when    = destroy
  command = <<-EOT
    echo "Removing kubeconfig files..."
    rm -f ../kubeconfig/kubeconfig-original.yaml
    rm -f ../kubeconfig/kubeconfig-tunneled.yaml
  EOT
}
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kops delete cluster \
        --name=${self.triggers.cluster_name} \
        --state=${self.triggers.s3_url}/${self.triggers.kops_state_store} \
        --yes
    EOT
  }

}
#  #--target=terraform \
