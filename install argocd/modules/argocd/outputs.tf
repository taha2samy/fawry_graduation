output "argocd_admin_password" {
  value       = random_password.argocd_admin_password.result
  description = "ArgoCD admin password"
}

output "credentials_file" {
  value       = local_file.credentials.filename
  description = "Path to credentials.txt file"
}

output "login_script_file" {
  value       = local_file.login_script.filename
  description = "Path to login script"
}
output "argocd_service_fqdn" {
  description = "The full internal DNS name (FQDN) of the ArgoCD server service."
  value       = "${data.kubernetes_service.argocd_server.metadata[0].name}.${data.kubernetes_service.argocd_server.metadata[0].namespace}.svc.cluster.local"
}


output "namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}
output "argocd_service_name" {
  value = data.kubernetes_service.argocd_server.metadata[0].name
}
output "argocd_service_port" {
  value = data.kubernetes_service.argocd_server.spec.0.port[0].port

}
