#!/bin/bash
set -e

echo "--> Logging into ArgoCD server at ${argocd_server_addr}..."
argocd login ${argocd_server_addr} --username ${argocd_username} --password '${argocd_password}' --insecure

echo "--> Adding/Updating Git repository: ${repo_url}..."
argocd repo add ${repo_url} --username ${repo_username} --password '${github_pat}' --upsert --insecure

echo "--> ArgoCD repository setup complete!"