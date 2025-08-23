provider "helm" {
  kubernetes = {
    config_path = "${path.root}/${var.kubeconfig_path}"
  }
}
provider "kubernetes" {
  config_path = "${path.root}/${var.kubeconfig_path}"
}
# Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}
resource "random_password" "argocd_admin_password" {
  length  = 16
  special = true
}
# Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  values     = [file("${path.root}/${var.values_file}")]

  set = [
    {
      name  = "configs.secret.argocdServerAdminPassword"
      value = nonsensitive(bcrypt(random_password.argocd_admin_password.result))
    }
  ]

}



# ArgoCD server hostname (from ingress)
data "kubernetes_ingress" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}

#Save credentials
resource "local_file" "credentials" {
  content  = <<EOT
username: admin
password: ${random_password.argocd_admin_password.result}
EOT
  filename = "${path.root}/../argocd/credentials.txt"
}

# Login script
resource "local_file" "login_script" {
  content = <<EOT
#!/bin/bash
argocd login localhost:8080 \
  --username admin \
  --password ${random_password.argocd_admin_password.result} \
  --insecure
EOT
  filename = "${path.root}/../argocd/argocd-login.sh"
}

resource "null_resource" "chmod_login" {
  provisioner "local-exec" {
    command = "chmod +x ${local_file.login_script.filename}"
  }
  depends_on = [local_file.login_script]
}
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}