variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace for ArgoCD"
}

variable "values_file" {
  type        = string
  description = "Path to helm values.yaml file"
}

variable "output_path" {
  type        = string
  default     = "./argocd"
  description = "Directory to store credentials and login script"
}

