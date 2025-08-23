apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mysql-app-${target_namespace}
  namespace: ${argocd_namespace}
spec:
  project: default
  source:
    repoURL: ${repo_url}
    targetRevision: ${mysql_revision}
    path: ${mysql_path}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${target_namespace}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true