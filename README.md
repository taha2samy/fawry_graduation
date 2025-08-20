
# Flask Application: Kubernetes Deployment with Kustomize

This directory contains all the Kubernetes manifests required to deploy the Flask application using a GitOps-friendly Kustomize structure.

## Deployment Strategy (Base + Overlays)

We use a standard base-and-overlay approach.
-   The `base/` directory contains the common, unchanging YAML definitions for the Deployment, Service, and Ingress.
-   The `overlays/` directory contains small, environment-specific patches. For example, it modifies the number of replicas for `staging` versus `production`.

This strategy avoids configuration drift and eliminates the need to duplicate YAML files for each environment.

### Directory Structure

```
.
└── kubernetes
    ├── base
    │   ├── deployment.yaml
    │   ├── ingress.yaml
    │   ├── kustomization.yaml
    │   └── service.yaml
    └── overlays
        ├── production
        │   ├── kustomization.yaml
        │   └── replicas.yaml
        └── staging
            ├── kustomization.yaml
            └── replicas.yaml```
```
## How to Deploy

To deploy the application, you will need `kubectl` installed and configured to connect to your Kubernetes cluster.

### Step 1: Prerequisite - Create the Database Secret

The application's Deployment requires a Kubernetes `Secret` named `mysql-credentials` to exist in the target namespace. This secret provides the application with the necessary credentials to connect to its database.

**⚠️ Important Security Note:**
This secret should be managed securely and **must not** be committed to the Git repository. For production, use a secrets management tool like Sealed Secrets or Vault.

To create the secret manually for the `staging` environment, run the following command:

```bash
# First, create the namespace if it doesn't exist
kubectl create namespace staging

# Create the secret with the database username and password
kubectl create secret generic mysql-credentials \
  --from-literal=username='your-staging-db-user' \
  --from-literal=password='your-staging-db-password' \
  -n staging
```
Repeat this step for the `production` namespace with the appropriate production credentials.

### Step 2: Preview the Manifests (Dry Run)

Before applying any changes, you can safely preview the final YAML that Kustomize will generate for a specific environment.

**For the `staging` environment:**
```bash
kubectl kustomize ./kubernetes/overlays/staging
```

**For the `production` environment:**
```bash
kubectl kustomize ./kubernetes/overlays/production
```
If these commands execute without errors and produce a valid YAML output, your configuration is correct.

### Step 3: Apply the Configuration

To deploy or update the application, use the `kubectl apply -k` command, pointing it to the desired overlay.

**Deploy to the `staging` environment:**
```bash
kubectl apply -k ./kubernetes/overlays/staging
```

**Deploy to the `production` environment:**
```bash
kubectl apply -k ./kubernetes/overlays/production
```
This command will create or update all the necessary resources (Deployment, Service, Ingress) in the specified namespace.

## Continuous Integration (CI) Validation

A GitHub Actions workflow is configured to automatically validate the Kustomize manifests.

-   **Trigger**: This check is triggered on every `push` to the `flask/service` branch.
-   **Action**: The `kustomize-check` job runs `kustomize build` on both the `staging` and `production` overlays. If there are any syntax errors or structural problems in the YAML or Kustomize files, the build will fail. This prevents broken configurations from being merged into the main development branch.
