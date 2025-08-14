data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "${path.root}/../global/terraform.tfstate"
  }
}

locals {
  subnet_ids = join(",", [
    for k, v in data.terraform_remote_state.network.outputs.k8s_subnets : v.id
  ])
  
  availability_zones = join(",", distinct([
    for k, v in data.terraform_remote_state.network.outputs.k8s_subnets : v.availability_zone
  ]))
  s3 = data.terraform_remote_state.network.outputs.s3_url
  
}

resource "null_resource" "kops_generate_terraform" {

  triggers = {
    cluster_name = var.kops_cluster_name
    network_id   = data.terraform_remote_state.network.outputs.vpc_id
    subnet_ids   = local.subnet_ids
    zones        = local.availability_zones
    dns_zone_id  = data.terraform_remote_state.network.outputs.private_zone_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      kops create cluster \
        --name=${self.triggers.cluster_name} \
        --state=${local.s3}/${var.kops_state_store} \
        --network-id=${self.triggers.network_id} \
        --subnets=${self.triggers.subnet_ids} \
        --zones=${self.triggers.zones} \
        --cloud=aws \
        --dns=private \
        --dns-zone=${self.triggers.dns_zone_id} \
        --node-count=2 \
        --node-size=t3.medium \
        --control-plane-size=t3.medium \
        --networking=calico \
        --target=terraform \
        --out=../k8s \
        --yes
    EOT
  }
}