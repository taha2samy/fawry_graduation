

resource "local_file" "kubeconfig_script_generator" {
  filename        = "../generate-kubeconfigs.sh"
  file_permission = "0755"

  content = templatefile("${path.module}/templates/generate-kubeconfigs.sh.tpl", {
    cluster_name = var.kops_cluster_name
    kops_state   = "${local.s3}/${var.kops_state_store}"
  })
}
locals {
  trimmed_private_key_file = substr(data.terraform_remote_state.network.outputs.private_key_file, 3, length(data.terraform_remote_state.network.outputs.private_key_file) - 3)

}
resource "local_file" "bash_script_ssl_tunnel" {
  filename        = "../start-tunnel.sh"
  file_permission = "0755"

  content = templatefile("${path.module}/templates/start-tunnel.sh.tpl", {
    cluster_name       = var.kops_cluster_name
    private_key_file   = local.trimmed_private_key_file
    bastion_public_dns = data.terraform_remote_state.network.outputs.public_dns
  })
}


