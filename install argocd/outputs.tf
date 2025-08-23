output "argocd_username" {
  value       = "admin"
  description = "ArgoCD admin username"
  sensitive   = false
}

output "argocd_password" {
  value       = module.argocd.argocd_admin_password
  description = "ArgoCD admin password"
  sensitive   = true
}

output "argocd_insecure" {
  value       = true
  description = "ArgoCD insecure flag"
}

output "argocd_service" {
  value       = module.argocd.argocd_service_fqdn
  description = "ArgoCD service FQDN"
}
