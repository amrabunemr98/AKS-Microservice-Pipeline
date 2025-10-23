## End-to-End Deployment Guide

The workflow below follows the requested sequence: build the container, provision Azure resources with Terraform modules, deploy to AKS with Helm, and enable monitoring and CI/CD automation.

### 1. Prerequisites

- Azure subscription with permissions to create resource groups, AKS, ACR, VNets, and VMs.
- Terraform `>= 1.5`, Azure CLI, Helm 3, Docker 24+, and kubectl.
- A GitHub repository containing this codebase with GitHub Actions enabled.
- An SSH public key for the jumpbox (`ssh-keygen -t ed25519 -C "you@example.com"`).

### 2. Container Image (local validation)

```bash
docker build -t microservice:local .
docker run -p 5000:5000 microservice:local
curl http://localhost:5000/users
```

### 3. Provision Azure infrastructure with Terraform

1. Navigate to `infra/terraform/environments/dev/`.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust:
   - `location`, `project_name`, and `environment`.
   - CIDR blocks for the virtual network and subnets (ensure non-overlapping ranges).
   - `ssh_public_key` and `allowed_ssh_cidrs`.
3. Configure the remote state backend in `provider.tf` (Azure Storage account recommended).
4. Authenticate with Azure: `az login` (or use a service principal).
5. Run Terraform:

```bash
terraform init
terraform plan
terraform apply
```

Terraform outputs:
- AKS cluster name and resource group.
- ACR login server.
- Jumpbox public IP (SSH entry point when the cluster is private).

### 4. Jumpbox access (private cluster administration)

```bash
ssh azureuser@<jumpbox_public_ip>
az login --use-device-code
az aks get-credentials --resource-group <rg> --name <aks_cluster_name>
kubectl get nodes
```

The AKS cluster is private; all `kubectl` or Helm operations must originate from the jumpbox, Azure Cloud Shell, or a peered network.

### 5. Build and push images manually (optional pre-pipeline)

```bash
az acr login --name <acr_name>
docker tag microservice:local <acr_login_server>/microservice:manual
docker push <acr_login_server>/microservice:manual
```

### 6. Helm deployment (manual)

```bash
helm upgrade --install microservice ./deploy/helm/microservice \
  --namespace microservice --create-namespace \
  --set image.repository=<acr_login_server>/microservice \
  --set image.tag=manual
kubectl get svc -n microservice microservice
```

Because the Service is internal (`service.beta.kubernetes.io/azure-load-balancer-internal: "true"`), access is limited to the virtual network. Use the jumpbox or a peered network to reach the service IP.

### 7. Monitoring stack (manual)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f deploy/monitoring/kube-prometheus-stack-values.yaml
kubectl get svc -n monitoring grafana
```

Grafana and Prometheus services default to internal load balancers. Port-forward from the jumpbox for browser access (`kubectl port-forward svc/grafana 3000:80 -n monitoring`).

### 8. GitHub Actions CI/CD

Create the following repository secrets (matching `.github/workflows/deploy.yml`):

- `AZURE_CREDENTIALS`: JSON from `az ad sp create-for-rbac --sdk-auth`.
- `AZURE_SUBSCRIPTION_ID`: Subscription ID.
- `ACR_NAME` and `ACR_LOGIN_SERVER`: e.g. `microservicesdevacr` and `microservicesdevacr.azurecr.io`.
- `AKS_RESOURCE_GROUP`: Resource group containing the AKS cluster.
- `AKS_CLUSTER_NAME`: Cluster name from Terraform output.
- `AKS_NAMESPACE`: Target namespace (e.g., `microservice`).

On push to `main` (or via manual dispatch), the workflow:
1. Logs into Azure.
2. Builds and pushes a Docker image tagged with the Git commit SHA.
3. Applies the Helm chart for the microservice.
4. Ensures the Prometheus/Grafana stack is installed/updated.

### 9. Observability stubs

- The Flask app currently lacks a metrics endpoint. Add Prometheus-compatible metrics (e.g., `prometheus_flask_exporter`) when ready.
- Grafana admin password defaults to `changeme` in `deploy/monitoring/kube-prometheus-stack-values.yaml`; override via `--set grafana.adminPassword=<secret>` or manage with Kubernetes secrets.

### 10. Next steps / production hardening

- Introduce user-defined routing and a firewall or Azure Bastion instead of a public SSH jumpbox.
- Enable Log Analytics integration for AKS and centralise logs in Azure Monitor.
- Parameterise Helm values via environment-specific `values` files.
- Expand Terraform modules to support multiple environments (staging, prod) by adding additional folders under `infra/terraform/environments/`.
