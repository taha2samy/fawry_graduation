variable "github_secret_arn" {
  default = "arn:aws:secretsmanager:eu-west-1:977098995259:secret:app-github-pat-token-37paqq"
}

variable "mysql_secret_arn" {
    default = "arn:aws:secretsmanager:eu-west-1:977098995259:secret:app-mysql-credentials-OGAXdd"
  
}
variable "mysql_secret_name" {
  default = "app-mysql-credentials"

}
variable "argocd_namespace" {
  default = "argocd"
}