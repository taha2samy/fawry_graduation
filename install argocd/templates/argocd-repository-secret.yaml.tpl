apiVersion: v1
kind: Secret
metadata:
  name: repo-fawry-graduation
  namespace: ${argocd_namespace}
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
data:
  url: ${base64encode(repo_url)}
  username: ${base64encode(repo_username)}
  password: ${base64encode(github_pat)}