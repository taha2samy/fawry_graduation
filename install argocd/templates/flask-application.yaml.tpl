apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: flask-app-${target_namespace}
  namespace: ${argocd_namespace}
spec:
  project: default
  source:
    repoURL: ${repo_url}
    targetRevision: ${flask_revision}
    path: ${flask_path}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${target_namespace}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true