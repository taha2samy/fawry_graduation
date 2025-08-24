locals {
  argocd_namespace = "argocd"
  target_namespace = "production"
  repo_url         = "https://github.com/taha2samy/fawry_graduation.git"
  mysql_revision   = "mysql/service"
  mysql_path       = "kubernetes/mysql-db/overlays/production"
  flask_revision   = "flask/service"
  flask_path       = "kubernetes/overlays/production"
}




module "argocd" {
  source          = "./modules/argocd"
  kubeconfig_path = "./../kubeconfig/kubeconfig-original.yaml"
  values_file     = "/argo-values-aws.yaml"
  output_path     = "./argocd"
  namespace       = local.argocd_namespace

}


data "aws_secretsmanager_secret_version" "mysql" {
  secret_id = var.mysql_secret_arn
}

locals {
  mysql_creds = jsondecode(data.aws_secretsmanager_secret_version.mysql.secret_string)
}

resource "local_file" "port_forward_script" {
  filename = "${path.root}/../argocd/argo_port_forwarding.sh"
  content  = templatefile("${path.module}/templates/port_forward.sh.tpl", {
    kubeconfig_path = "./../kubeconfig-original.yaml"
    service_name    = "argocd-server"
    namespace       = local.argocd_namespace
    service_port    = 443
    local_port      = 8080
  })
}

resource "local_file" "mysql_app" {
  filename = "${path.module}/../install apps/mysql-application.yaml"
  content  = templatefile("${path.module}/templates/mysql-application.yaml.tpl", {
    argocd_namespace = local.argocd_namespace
    target_namespace = local.target_namespace
    repo_url         = local.repo_url
    mysql_revision   = local.mysql_revision
    mysql_path       = local.mysql_path
  })
}

resource "local_file" "flask_app" {
  filename = "${path.module}/../install apps/flask-application.yaml"
  content  = templatefile("${path.module}/templates/flask-application.yaml.tpl", {
    argocd_namespace = local.argocd_namespace
    target_namespace = local.target_namespace
    repo_url         = local.repo_url
    flask_revision   = local.flask_revision
    flask_path       = local.flask_path
  })
}

resource "local_file" "mysql_secret" {
  filename = "${path.module}/../install apps/mysql-secret.yaml"
  content  = templatefile("${path.module}/templates/mysql-secret.yaml.tpl", {
    target_namespace    = local.target_namespace
    mysql_root_password = local.mysql_creds.MYSQL_ROOT_PASSWORD
    mysql_database      = local.mysql_creds.MYSQL_DATABASE
    mysql_user          = local.mysql_creds.MYSQL_USER
    mysql_password      = local.mysql_creds.MYSQL_PASSWORD
  })

}

data "aws_secretsmanager_secret_version" "github" {
  secret_id = var.github_secret_arn
}

locals {
  github_pat    = jsondecode(data.aws_secretsmanager_secret_version.github.secret_string).PAT
  repo_username = "taha2samy"
}


resource "local_file" "repo_setup_script" {
  filename        = "${path.module}/../argocd/add-repo.sh"
  file_permission = "0755"
  content         = templatefile("${path.module}/templates/setup-repo.sh.tpl", {
    argocd_server_addr = "localhost:8080"
    argocd_username    = "admin"
    argocd_password    = module.argocd.argocd_admin_password
    repo_url           = local.repo_url
    repo_username      = local.repo_username
    github_pat         = local.github_pat
  })
}
