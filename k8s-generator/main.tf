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
}

resource "null_resource" "kops_generate_terraform" {

  triggers = {
    cluster_name       = var.kops_cluster_name
    network_id         = data.terraform_remote_state.network.outputs.vpc_id
    vpc_cidr           = data.terraform_remote_state.network.outputs.vpc_cidr_block
    private_subnet_ids = local.private_subnet_ids
    utility_subnet_ids = local.utility_subnet_ids
    zones              = local.availability_zones
    dns_zone_id        = data.terraform_remote_state.network.outputs.private_zone_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      kops create cluster \
        --name=${self.triggers.cluster_name} \
        --state=${local.s3_url}/${var.kops_state_store} \
        --cloud=aws \
        --network-id=${self.triggers.network_id} \
        --network-cidr=${self.triggers.vpc_cidr} \
        --subnets=${self.triggers.private_subnet_ids} \
        --utility-subnets=${self.triggers.utility_subnet_ids} \
        --topology=private \
        --zones=${self.triggers.zones} \
        --control-plane-zones=${self.triggers.zones} \
        --dns=private \
        --dns-zone=${self.triggers.dns_zone_id} \
        --node-count=3 \
        --node-size=t3.medium \
        --control-plane-size=t3.medium \
        --networking=calico \
        --ssh-public-key=../ssh\ keys/public.pub \
        --target=terraform \
        --out=../k8s \
        --yes
    EOT
  }
}