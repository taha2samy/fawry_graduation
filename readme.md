
# The Resilient & Cost-Effective Kubernetes Platform on AWS

<p align="center">
  
![My Architecture Diagram](images/Untitled%20Diagram.drawio.svg)

</p>

<p align="center">
  <em>An enterprise-ready, fully automated platform for deploying and managing high-availability applications on Kubernetes. This project is a masterclass in Infrastructure as Code (IaC) and GitOps, meticulously engineered to deliver maximum resilience, developer velocity, and radical cost-efficiency.</em>
</p>

<p align="center">
    <a href="https://www.terraform.io/">
        <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform">
    </a>
    <a href="https://kops.sigs.k8s.io/">
        <img src="https://img.shields.io/badge/Kops-00ADD8?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kops">
    </a>
    <a href="https://argo-cd.readthedocs.io/en/stable/">
        <img src="https://img.shields.io/badge/Argo%20CD-F4722B?style=for-the-badge&logo=argo&logoColor=white" alt="Argo CD">
    </a>
    <a href="https://helm.sh/">
        <img src="https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm">
    </a>
    <a href="https://aws.amazon.com/">
        <img src="https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS">
    </a>
</p>

---

## 🏛️ Architectural Philosophy: Beyond the Tools

This platform was built not as a checklist of technologies, but as a cohesive ecosystem founded on battle-tested SRE principles. Every component and automation script serves a strategic purpose.

*   **Resilience by Design (Multi-AZ):** The entire architecture, from the VPC subnets to the Kubernetes control plane and worker nodes, is distributed across multiple AWS Availability Zones. This design ensures business continuity by eliminating single points of failure, tolerating the loss of an entire data center.

*   **Security Through Isolation:** A strict network segmentation model is enforced. The Kubernetes data plane (worker nodes) and control plane reside in private subnets, completely isolated from the public internet. All inbound traffic is managed through controlled entry points, and outbound traffic is routed securely.

*   **Git as the Immutable Source of Truth (GitOps):** We treat our infrastructure and application configurations with the same rigor as our application code. Git is the single source of truth. All changes are declarative, peer-reviewed, and auditable through pull requests, leading to a stable and predictable operational state managed by ArgoCD.

*   **Radical Cost-Optimization (The `fck-nat` Strategy):** In cloud-native environments, networking costs can become a significant and often overlooked expense. Standard AWS NAT Gateways are powerful but prohibitively expensive for many workloads. This platform makes a deliberate, cost-conscious architectural decision:
    > We replace the standard NAT Gateway with a highly available, open-source **`fck-nat` Bastion server** running on a cost-effective EC2 instance. This strategic move **dramatically reduces recurring networking costs—often by over 90%**—while providing robust and secure egress connectivity for all private resources. This is not just cost-saving; it is intelligent, pragmatic engineering.

---

## 🕹️ The Platform Control Center: A Deep Dive into the Automation Engine

The true power of this platform lies in its fully integrated **Control Center** within VS Code. This is not merely a list of scripts; it is a sophisticated orchestration layer (`tasks.json`) that transforms the operator into a true platform conductor. It eliminates manual error, enforces best practices, and provides unparalleled operational velocity.

### **I. Infrastructure Lifecycle Orchestration (`Terraform & Kops`)**

These tasks manage the very fabric of the platform, from the virtual network to the Kubernetes cluster itself.

| Task                                 | Description                                                                                                                                     |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `✅ Full Apply: Infrastructure`        | **One-Click Provisioning:** A master workflow that sequences Terraform and Kops commands to build the entire platform from zero.                  |
| `❌ Full Destroy: Infrastructure`      | **Atomic Teardown:** Safely destroys all infrastructure resources in the correct dependency order, preventing orphaned resources.                   |
| `Global: Apply / Destroy`            | **Granular Network Control:** Manages the foundational AWS VPC, subnets, and IAM roles. Allows for isolated network changes.                          |
| `K8s Generator: Apply / Destroy`     | **Cluster Fabric Management:** Manages the Kops-specific resources and cluster specifications.                                                      |
| `Kops: Create / Update / Rolling`    | **Advanced Cluster Operations:** Provides fine-grained control over the Kubernetes cluster lifecycle, including zero-downtime rolling updates.       |

### **II. Application & GitOps Fleet Management (`ArgoCD & Helm`)**

This suite of commands bootstraps and manages the continuous delivery engine of the platform.

| Task                           | Description                                                                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `✅ Full Apply: Applications`    | **GitOps Bootstrap:** A meta-task that installs ArgoCD, configures its repositories, and applies the root application manifests.     |
| `ArgoCD: Install / Destroy`    | **Engine Management:** Uses Terraform to declaratively manage the ArgoCD installation within the cluster.                              |
| `ArgoCD: 🔌 Port Forward`        | **Instant UI Access:** Opens a secure tunnel to the ArgoCD web UI for visual inspection of the application fleet's health and sync status. |
| `Apps (Manifests): Apply`      | **Declarative App Deployment:** Applies the root ArgoCD application definitions, which in turn manage all other applications in the cluster. |

### **III. Real-time Diagnostics & Introspection (`kubectl`)**

The Control Center provides powerful "in-situ" debugging capabilities, allowing operators to diagnose issues without ever leaving their development environment. This eliminates context switching and dramatically reduces Mean Time to Resolution (MTTR).

| Task                                     | Description                                                                                                                                  |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `$(debug-breakpoint-log) Follow Deployment Logs` | **Live Log Streaming:** Instantly tails logs from all containers in a specific deployment, providing a real-time view of application behavior. |
| `Kube: 🐳 Exec into Pod (sh)`              | **Interactive Troubleshooting:** Opens a secure shell directly inside any running container for deep, hands-on debugging.                          |
| `Kube: 🔎 Describe Pod`                    | **Event Forensics:** Retrieves a detailed event log and status description for any pod, crucial for diagnosing scheduling or startup issues.    |
| `Kube: 📜 View ... YAML`                   | **Live State Inspection:** Fetches the live Kubernetes API object definition (for Pods, Deployments, etc.) as it exists in the cluster.           |

This deeply integrated automation transforms platform management from a high-risk, manual chore into a reliable, repeatable, and efficient engineering discipline.

---

## 🚀 Getting Started: From Zero to a Live GitOps Platform

This guide provides the streamlined, automated steps to provision the entire platform from a clean AWS account. The entire workflow is orchestrated through the **Platform Control Center** within VS Code, ensuring a repeatable and error-free setup.

### **Phase 0: Prerequisites & Environment Setup**

Before launching the platform, ensure your local environment is correctly configured.

1.  **Install Core CLI Tools:**
    *   [AWS CLI](https://aws.amazon.com/cli/)
    *   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    *   [Kops](https://kops.sigs.k8s.io/getting_started/install/)
    *   [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

2.  **Configure AWS Credentials:**
    *   Ensure your AWS CLI is configured with an IAM user possessing permissions to create VPCs, EC2 instances, S3 buckets, and IAM roles.
    *   Run `aws configure` and provide your access key, secret key, and default region.

3.  **Prepare the Kops State Store:**
    *   Kops requires a versioned S3 bucket to maintain the state of your cluster. Create one in your AWS account.
    *   **Important:** Enable versioning on the bucket as it is a Kops requirement.
    ```bash
    # Example commands to create and version the bucket
    aws s3api create-bucket --bucket your-unique-kops-state-store --region us-east-1
    aws s3api put-bucket-versioning --bucket your-unique-kops-state-store --versioning-configuration Status=Enabled
    ```

4.  **Configure the Project Environment:**
    *   The project's central configuration is managed via a `.env` file.
    *   First, copy the template: `cp .env.example .env`
    *   Next, edit the new `.env` file and define the `CLUSTER_NAME` and `KOPS_STATE_STORE` variables with your specific values.

### **Phase 1: The One-Click Platform Provisioning**

This is where the power of the Platform Control Center shines. The entire infrastructure and cluster bring-up process is a single, orchestrated command.

1.  **Launch the Control Center:** Open the command palette in VS Code (`Ctrl+ShiftP` or `Cmd+Shift+P`).
2.  **Select and Run Task:** Type `Run Task` and select `✅ Full Apply: Infrastructure`.
3.  **Monitor the Orchestration:** A dedicated terminal will open and display the progress as the automation engine executes the entire workflow:
    *   First, **Terraform** provisions the foundational AWS infrastructure (VPC, Multi-AZ subnets, security groups, and the `fck-nat` instance).
    *   Then, **Kops** takes over to build the production-grade Kubernetes cluster on top of that infrastructure.
    *   This fully automated process typically takes 10-15 minutes. Grab a coffee and watch the magic happen.

### **Phase 2: Cluster Health Validation**

Once the provisioning task completes, it's crucial to verify that the cluster is healthy and fully operational.

1.  **Validate with Kops:** From the Control Center, run the task `Kops: ✅ Validate Cluster`.
    *   This command performs a deep health check on all cluster components. The expected output is a message stating `Your cluster is ready`.

2.  **Interact with kubectl:**
    ```bash
    # This command lists all the nodes in your cluster (control plane and workers)
    kubectl get nodes -o wide
    ```
    *   You should see multiple nodes listed, with their roles and IP addresses, distributed across the different Availability Zones you defined.

### **Phase 3: Activating the GitOps Engine**

With a healthy cluster, the final step is to bring the platform to life by bootstrapping the ArgoCD GitOps engine.

1.  **Run the Application Bootstrap Task:** From the VS Code Control Center, run the task `✅ Full Apply: Applications`.
2.  **Behind the Scenes:** This task uses Terraform to install ArgoCD into the cluster and immediately configures it to monitor your application's Git repository and the specific branches (`<app-name>/service`).
3.  **Access the ArgoCD Dashboard:** Run the task `ArgoCD: 🔌 Port Forward`. This will open a secure tunnel and provide a link to the ArgoCD web UI in the terminal.

**Congratulations! Your production-grade, cost-effective Kubernetes platform is now fully operational and managed by GitOps.** To deploy, update, or roll back an application, simply make a declarative change in the corresponding `/service` branch in Git, and ArgoCD will handle the rest.

---

## 💣 Tearing Down the Environment: Clean & Complete De-provisioning

To avoid ongoing AWS costs, it is **critical** to destroy all resources when you are finished. The Control Center provides a safe, orchestrated, and complete teardown process.

1.  **Destroy Applications & GitOps Engine:**
    *   Run the VS Code task `❌ Full Destroy: Applications`.
    *   This ensures ArgoCD and all its managed applications are cleanly uninstalled from the cluster first.

2.  **Destroy the Cluster & Infrastructure:**
    *   Run the VS Code task `❌ Full Destroy: Infrastructure`.
    *   This master task executes `kops delete` and `terraform destroy` in the correct reverse dependency order, ensuring no orphaned resources are left behind in your AWS account.




## 🐙 GitOps in Action: The Application Lifecycle & Branching Strategy

This platform's power is fully realized through its opinionated Git branching strategy. We go beyond a simple `main` branch to create a structured, automated pathway from source code to a live production environment. This methodology enforces a strict **separation of concerns** between the application's code and its deployment configuration, which is fundamental to a stable and secure GitOps workflow.

The entire application lifecycle is managed through a specific branch naming convention:

-   **`<app-name>/main`**: Contains the application's source code.
-   **`<app-name>/service`**: Contains the application's deployment configuration (Helm Chart).

Here is a detailed breakdown of each component's role and its associated automation pipeline:

| Branch Pattern                                      | Purpose & Responsibilities                                                                                                                                                                                                     | CI/CD Automation Pipeline                                                                                                                                                                                                           |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`flask/main`**, **`mysql/main`**, etc.            | **📦 Application Source Code**<br>This is the developer's domain. It contains the application logic, `Dockerfile`, unit tests, and all dependencies. The primary output of this branch is a versioned, immutable Docker image.             | **Continuous Integration (CI):**<br>1. **Trigger:** On every push or merge.<br>2. **Test:** Run static analysis, linters, and a full suite of unit/integration tests.<br>3. **Build:** Build a new Docker image with a unique version tag (e.g., Git SHA).<br>4. **Push:** Push the tested image to the container registry (e.g., AWS ECR, Docker Hub). |
| **`flask/service`**, **`mysql/service`**, etc.      | **🚀 Kubernetes Deployment Configuration (Helm)**<br>This is the operator's domain and the **single source of truth for ArgoCD**. It contains the Helm chart (`Chart.yaml`, `values.yaml`, templates) that declaratively defines *how* the application should run in Kubernetes. | **Continuous Delivery (CD) & Validation:**<br>1. **Trigger:** On every push or merge.<br>2. **Validate:** Run `helm lint` and other static tests to ensure the chart is syntactically correct.<br>3. **Automatic Sync (via ArgoCD):** ArgoCD is configured to constantly watch this branch. Any change here automatically triggers a deployment/update in the Kubernetes cluster. |

### Visualizing the End-to-End Workflow

Let's walk through a typical deployment scenario to see how these pieces work together seamlessly:

1.  **Code Change:** A developer pushes a new feature to the `flask/main` branch.
2.  **CI Pipeline Runs:** The CI pipeline automatically triggers. It tests the code, builds a new Docker image tagged `my-flask-app:v1.2.4`, and pushes it to the container registry. **No changes happen in the cluster yet.**
3.  **Declarative Update:** To deploy this new version, the developer (or a release manager) creates a pull request against the `flask/service` branch. The only change is in the `values.yaml` file:
    ```yaml
    # values.yaml in flask/service branch
    image:
      repository: my-flask-app
      tag: "v1.2.4" # Changed from "v1.2.3"
    ```
4.  **Review and Merge:** The pull request is reviewed and merged.
5.  **ArgoCD Takes Over:** The moment the change is merged into `flask/service`, ArgoCD detects it.
6.  **Zero-Downtime Deployment:** ArgoCD compares the new desired state (from Git) with the live state in Kubernetes. It then executes a `helm upgrade` process, triggering a rolling update of the Flask application pods to the new `v1.2.4` image with zero downtime.

This methodology provides a robust, auditable, and highly automated path to production, empowering developers to ship features quickly while giving operators full control and visibility over the production environment.
