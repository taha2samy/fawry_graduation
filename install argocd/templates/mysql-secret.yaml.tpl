apiVersion: v1
kind: Secret
metadata:
  name: mysql-credentials
  namespace: ${target_namespace}
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: ${base64encode(mysql_root_password)}
  MYSQL_DATABASE: ${base64encode(mysql_database)}
  MYSQL_USER: ${base64encode(mysql_user)}
  MYSQL_PASSWORD: ${base64encode(mysql_password)}