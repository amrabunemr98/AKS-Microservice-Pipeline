# Microservices Deployment on Azure Kubernetes Service (AKS)

A complete production-ready microservices deployment on Azure Kubernetes Service with automated CI/CD, monitoring, and alerting capabilities.

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Infrastructure Setup](#infrastructure-setup)
  - [Bootstrap Infrastructure](#bootstrap-infrastructure)
  - [Main Infrastructure](#main-infrastructure)
- [Jumpbox Configuration](#jumpbox-configuration)
- [GitHub Actions Self-Hosted Runners](#github-actions-self-hosted-runners)
- [Application Deployment](#application-deployment)
- [Monitoring Setup](#monitoring-setup)
  - [Prometheus](#prometheus)
  - [Grafana](#grafana)
  - [Alerting Rules](#alerting-rules)
- [Troubleshooting](#troubleshooting)
- [Azure Subscription Limitations](#azure-subscription-limitations)
- [Access Information](#access-information)

---

## Project Overview

This project demonstrates a complete DevOps implementation featuring:
- **Infrastructure as Code (IaC)** using Terraform
- **Azure Kubernetes Service (AKS)** for container orchestration
- **Microservices application** deployed via Helm charts
- **CI/CD pipeline** using GitHub Actions with self-hosted runners
- **Monitoring and observability** with Prometheus and Grafana
- **Alerting** for HTTP 404/500 errors

### Key Features
- Automated infrastructure provisioning
- GitOps deployment workflow
- Production-grade monitoring stack
- Cost-optimized architecture with public IP limitations
- External access to services without ingress conflicts

---

## Architecture

### Service Access Design
- **Microservice Application**: Uses Kubernetes LoadBalancer service with dedicated public IP (132.196.184.141)
- **Monitoring Services**: Uses ingress-nginx controller with Jumpbox public IP (20.1.152.210)
- **IP Optimization**: Jumpbox public IP detached and reassigned to ingress controller to stay within 3 IP limit

---

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and configured
- Terraform >= 1.0
- kubectl
- Helm 3.x
- Git and GitHub account
- GitHub Personal Access Token (for self-hosted runners)

---

## Infrastructure Setup

### SSH Key Generation for Jumpbox Access

Before deploying infrastructure, generate an SSH key pair to access the Jumpbox VM.

#### Steps:

1. **Generate SSH key pair** (if you don't already have one)
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

2. **Get your public IP address**
   ```bash
   curl ifconfig.me
   ```

   Note this IP address (e.g., `203.0.113.45`)

3. **Update Terraform variables**

   Edit your Terraform variables file and update:
   ```hcl
   # Replace with your actual public IP
   allowed_ssh_cidrs = ["203.0.113.45/32"]

   # Path to your SSH public key
   ssh_public_key_path = "~/.ssh/id_rsa.pub"
   ```

   **Important:** Make sure your local IP is within `allowed_ssh_cidrs` or you won't be able to SSH into the Jumpbox.

---

### Bootstrap Infrastructure

The bootstrap phase creates the foundational resources for storing Terraform state remotely.

#### Steps:

1. **Navigate to bootstrap directory**
   ```bash
   cd infra/terraform/bootstrap
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

   **[SCREENSHOT PLACEHOLDER: Bootstrap terraform init output]**

3. **Apply bootstrap configuration**
   ```bash
   terraform apply
   ```

   **[SCREENSHOT PLACEHOLDER: Bootstrap terraform apply output showing storage account and container creation]**

#### Bootstrap Resources Created:
- Azure Storage Account for Terraform state
- Storage Container for state files
- Resource Group for bootstrap resources

---

### Main Infrastructure

The main infrastructure provisions all Azure resources required for the AKS cluster and supporting services.

#### Steps:

1. **Navigate to main infrastructure directory**
   ```bash
   cd infra/terraform
   ```

2. **Initialize Terraform with remote backend**
   ```bash
   terraform init
   ```

   **[SCREENSHOT PLACEHOLDER: Main terraform init output with backend configuration]**

3. **Apply infrastructure configuration**
   ```bash
   terraform apply
   ```

   **[SCREENSHOT PLACEHOLDER: Terraform apply output showing all resources being created]**

4. **Review outputs**
   ```bash
   terraform output
   ```

   **[SCREENSHOT PLACEHOLDER: Terraform outputs showing AKS cluster name, resource group, jumpbox IP, etc.]**

#### Infrastructure Resources Created:
- **Virtual Network** with subnets for AKS and Jumpbox
- **AKS Cluster** (microservices-dev-aks)
- **NAT Gateway** for AKS egress traffic (uses 1 public IP)
- **Jumpbox VM** for cluster access (public IP will be detached later)
- **Network Security Groups** with appropriate rules
- **3 Public IP addresses** (NAT Gateway, Microservice LoadBalancer, Monitoring Ingress)
- **Azure Container Registry** (if configured)

---

## Jumpbox Configuration

After infrastructure deployment, configure the Jumpbox to access the AKS cluster.

#### Steps:

1. **SSH into Jumpbox** (while it still has public IP)
   ```bash
   ssh azureuser@<JUMPBOX_PUBLIC_IP>
   ```

   **[SCREENSHOT PLACEHOLDER: SSH connection to Jumpbox]**

2. **Install required tools on Jumpbox**

   Update system and install Docker:
   ```bash
   sudo apt update
   sudo apt install -y docker.io
   sudo systemctl enable --now docker
   sudo usermod -aG docker $USER
   ```

   Install kubectl (latest stable version):
   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

   # Move it into PATH and make it executable
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

   # Verify installation
   kubectl version --client
   ```

   **[SCREENSHOT PLACEHOLDER: kubectl version output]**

   Install Helm 3:
   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

   **[SCREENSHOT PLACEHOLDER: Helm installation output]**

3. **Authenticate with Azure and get AKS credentials**
   ```bash
   az login

   az aks get-credentials \
     --resource-group microservices-dev-rg \
     --name microservices-dev-aks
   ```

   **[SCREENSHOT PLACEHOLDER: AKS credentials configuration output]**

4. **Verify cluster access**
   ```bash
   kubectl get nodes
   ```

   **[SCREENSHOT PLACEHOLDER: kubectl get nodes showing AKS cluster nodes]**

5. **Check pods across all namespaces**
   ```bash
   kubectl get pods -A
   ```

   **[SCREENSHOT PLACEHOLDER: kubectl get pods output showing system pods]**

6. **Verify services**
   ```bash
   kubectl get svc --all-namespaces
   ```

   **[SCREENSHOT PLACEHOLDER: kubectl get services output]**

---

## GitHub Actions Self-Hosted Runners

To enable GitHub Actions to deploy to the AKS cluster, self-hosted runners are configured on the Jumpbox.

#### Steps:

1. **On Jumpbox, download GitHub Actions runner**
   ```bash
   mkdir actions-runner && cd actions-runner
   curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
   tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
   ```

2. **Configure the runner**
   ```bash
   ./config.sh --url https://github.com/<YOUR_USERNAME>/<YOUR_REPO> --token <GITHUB_TOKEN>
   ```

   **[SCREENSHOT PLACEHOLDER: GitHub runner configuration output]**

3. **Install and start runner as a service**

   Install runner as a service so it survives reboots:
   ```bash
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```

   Verify service status:
   ```bash
   sudo ./svc.sh status
   ```

   **[SCREENSHOT PLACEHOLDER: GitHub runner service status output]**

4. **Verify runner is online**
   - Navigate to GitHub repository → Settings → Actions → Runners

   **[SCREENSHOT PLACEHOLDER: GitHub UI showing self-hosted runner online]**

---

### Azure Service Principal for GitHub Actions

Create an Azure service principal to allow GitHub Actions workflow to authenticate and deploy resources to Azure.

#### Steps:

1. **Create service principal with Contributor role**
   ```bash
   az ad sp create-for-rbac \
     --name microservices-actions \
     --role Contributor \
     --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
     --sdk-auth
   ```

   Replace `YOUR_SUBSCRIPTION_ID` with your actual Azure subscription ID.

   **[SCREENSHOT PLACEHOLDER: Service principal creation output]**

2. **Copy the JSON output**

   The output will look like this:
   ```json
   {
     "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
     "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     ...
   }
   ```

3. **Add to GitHub Secrets**
   - Navigate to GitHub repository → Settings → Secrets and variables → Actions
   - Create a new repository secret named `AZURE_CREDENTIALS`
   - Paste the entire JSON output as the value

   **[SCREENSHOT PLACEHOLDER: GitHub secrets configuration]**

4. **Add additional secrets** (if needed)
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `AZURE_TENANT_ID`: Your Azure tenant ID
   - Any other sensitive values used in the workflow

---

## Application Deployment

The microservices application is automatically deployed via GitHub Actions CI/CD pipeline.

### Deployment Workflow

#### GitHub Actions Pipeline Steps:
1. Code checkout
2. Build Docker image
3. Push to container registry
4. Detach Jumpbox public IP and reassign to monitoring ingress
5. Deploy ingress-nginx controller with public IP
6. Deploy microservice using Helm
7. Deploy monitoring stack (Prometheus + Grafana)
8. Apply monitoring ingress configuration

#### Trigger Deployment:

1. **Push code to main branch**
   ```bash
   git add .
   git commit -m "Deploy microservices"
   git push origin main
   ```

2. **Monitor pipeline execution**
   - Navigate to GitHub repository → Actions

   **[SCREENSHOT PLACEHOLDER: GitHub Actions workflow running]**

   **[SCREENSHOT PLACEHOLDER: GitHub Actions workflow completed successfully]**

### Verify Deployment

**Check deployed pods:**
```bash
kubectl get pods -n microservice
```

**[SCREENSHOT PLACEHOLDER: kubectl get pods -n microservice showing running pods]**

**Check services:**
```bash
kubectl get svc -n microservice
```

**[SCREENSHOT PLACEHOLDER: kubectl get svc showing LoadBalancer service with external IP]**

---

## Monitoring Setup

### Prometheus

Prometheus is deployed using the kube-prometheus-stack Helm chart for metrics collection and monitoring.

#### Verify Prometheus Deployment:

```bash
kubectl get pods -n monitoring | grep prometheus
kubectl get svc -n monitoring | grep prometheus
```

**[SCREENSHOT PLACEHOLDER: Prometheus pods and services running]**

#### Access Prometheus UI:

- URL: `http://20.1.152.210/prometheus`
- Access via browser

**[SCREENSHOT PLACEHOLDER: Prometheus UI showing targets and service discovery]**

**[SCREENSHOT PLACEHOLDER: Prometheus UI showing metrics query with microservice data]**

#### Key Prometheus Metrics Collected:
- Kubernetes cluster metrics (nodes, pods, containers)
- Microservice HTTP requests and response codes
- Container CPU and memory usage
- Network traffic metrics

---

### Grafana

Grafana provides visualization dashboards for all collected metrics.

#### Verify Grafana Deployment:

```bash
kubectl get pods -n monitoring | grep grafana
kubectl get svc -n monitoring | grep grafana
```

**[SCREENSHOT PLACEHOLDER: Grafana pod and service running]**

#### Access Grafana UI:

- URL: `http://20.1.152.210/grafana`
- Default credentials: `admin` / `changeme`

**[SCREENSHOT PLACEHOLDER: Grafana login page]**

**[SCREENSHOT PLACEHOLDER: Grafana home dashboard]**

#### Configure Prometheus Datasource:

1. Navigate to Configuration → Data Sources → Add data source
2. Select Prometheus
3. URL: `http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/prometheus`
4. Click "Save & Test"

**[SCREENSHOT PLACEHOLDER: Grafana datasource configuration]**

#### Import Kubernetes Dashboards:

**Dashboard IDs:**
- **15661** - Kubernetes Cluster Monitoring
- **6417** - Kubernetes Cluster Overview

**[SCREENSHOT PLACEHOLDER: Grafana dashboard showing Kubernetes cluster metrics]**

**[SCREENSHOT PLACEHOLDER: Grafana dashboard showing pod CPU and memory usage]**

---

### Alerting Rules

Custom Prometheus alerting rules for monitoring HTTP errors from microservice pods.

#### Alert Rules Created:

**File:** `deploy/monitoring/microservice-alerts.yaml`

| Alert Name | Condition | Severity | Description |
|------------|-----------|----------|-------------|
| `MicroserviceHigh404Rate` | 404 errors > 0.1/sec for 2min | warning | High rate of 404 errors |
| `MicroserviceHigh500Rate` | 500 errors > 0.05/sec for 2min | critical | High rate of 500 errors |
| `MicroserviceAny404Error` | Any 404 error in 5min | info | 404 errors detected |
| `MicroserviceAny500Error` | Any 500 error in 5min | warning | 500 errors detected |
| `MicroserviceHighErrorRate` | Error rate > 5% for 5min | warning | High overall error rate |

#### Apply Alerting Rules:

```bash
kubectl apply -f deploy/monitoring/microservice-alerts.yaml
```

#### Verify Alerts in Prometheus:

Navigate to Prometheus UI → Alerts

**[SCREENSHOT PLACEHOLDER: Prometheus alerts page showing configured rules]**

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: External Access to Microservice Timeout

**Problem:**
```bash
curl http://132.196.184.141/users/1
# Connection timeout
```

**Root Cause:** Azure Load Balancer configured with `enableFloatingIP: true` causing Direct Server Return (DSR) mode issues.

**Solution:** Added annotation to disable floating IP:
```yaml
service:
  annotations:
    service.beta.kubernetes.io/azure-disable-load-balancer-floating-ip: "true"
```

**Manual fix applied:**
```bash
az network lb rule update \
  --resource-group MC_microservices-dev-rg_microservices-dev-aks_eastus2 \
  --lb-name kubernetes \
  --name <rule-name> \
  --enable-floating-ip false \
  --backend-port 31837
```

---

#### Issue 2: Monitoring Ingress (Grafana/Prometheus) Not Accessible

**Problem:**
```bash
curl http://20.1.152.210/grafana
# 404 Not Found or timeout
```

**Root Cause:**
1. Same floating IP issue with ingress-nginx LoadBalancer
2. Incorrect ingress path rewrite rules

**Solution 1:** Added floating IP disable annotation to ingress controller:
```bash
kubectl annotate svc ingress-nginx-controller -n ingress-nginx \
  service.beta.kubernetes.io/azure-disable-load-balancer-floating-ip="true" --overwrite
```

**Solution 2:** Updated Prometheus configuration with correct routing:
```yaml
prometheus:
  prometheusSpec:
    externalUrl: http://20.1.152.210/prometheus/
    routePrefix: /prometheus
```

**Solution 3:** Removed incorrect rewrite annotations from ingress resource.

---

#### Issue 3: Grafana Cannot Query Prometheus (404 Error)

**Problem:** Grafana datasource test fails with "404 Not Found"

**Root Cause:** Prometheus datasource URL missing `/prometheus` path suffix

**Solution:** Updated datasource URL to:
```
http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/prometheus
```

---

#### Issue 4: No Metrics Data in Grafana

**Problem:** Imported dashboards show "No data"

**Root Cause:** Prometheus not scraping microservice pods (initially, before we discovered Flask metrics were already enabled)

**Solution:** Verified that microservice already exposes Flask HTTP metrics:
```promql
flask_http_request_total{namespace="microservice"}
```

Working queries for microservice monitoring:
```promql
# Pod status
up{namespace="microservice"}

# CPU usage
rate(container_cpu_usage_seconds_total{namespace="microservice",container="microservice"}[5m])

# Memory usage
container_memory_working_set_bytes{namespace="microservice",container="microservice"}

# HTTP requests by status code
flask_http_request_total{namespace="microservice"}
```

---

## Azure Subscription Limitations

### Public IP Address Quota: 3 IPs Maximum

This Azure subscription has a limit of **3 public IP addresses**. To work within this constraint, the following strategy was implemented:

#### IP Allocation Strategy:

| Public IP | Usage | Notes |
|-----------|-------|-------|
| **IP 1** | NAT Gateway for AKS | Required for AKS nodes to pull container images from external registries (Docker Hub, GitHub Container Registry) |
| **IP 2** | Microservice LoadBalancer (132.196.184.141) | Direct external access to microservice application |
| **IP 3** | Monitoring Ingress (20.1.152.210) | Originally assigned to Jumpbox, detached and reassigned to ingress-nginx controller |

#### Jumpbox IP Detachment Process:

During the GitHub Actions deployment pipeline, the Jumpbox public IP is automatically detached and reassigned:

```yaml
- name: Detach Jumpbox public IP from VM
  run: |
    echo "Detaching public IP from Jumpbox to reassign to monitoring ingress..."
    JUMPBOX_NIC_ID=$(az vm show -g microservices-dev-rg -n microservices-dev-jumpbox \
      --query networkProfile.networkInterfaces[0].id -o tsv)
    JUMPBOX_NIC_NAME=$(basename "$JUMPBOX_NIC_ID")

    az network nic ip-config update \
      --resource-group microservices-dev-rg \
      --nic-name "$JUMPBOX_NIC_NAME" \
      --name ipconfig1 \
      --remove publicIpAddress || true
```

**Impact:** After deployment, Jumpbox is only accessible from within the Azure virtual network or via Azure Bastion (if configured).

**Alternative Access Methods:**
- Use Azure Cloud Shell
- Configure Azure Bastion for secure access
- Access via VPN to the VNet

---

## Access Information

### Application Endpoints

| Service | URL | Description |
|---------|-----|-------------|
| Microservice API | http://132.196.184.141/users/1 | Sample API endpoint |
| Prometheus | http://20.1.152.210/prometheus | Metrics collection UI |
| Grafana | http://20.1.152.210/grafana | Monitoring dashboards |

**[SCREENSHOT PLACEHOLDER: Browser showing microservice API response at http://132.196.184.141/users/1]**

### Grafana Credentials

- **Username:** `admin`
- **Password:** `changeme`
- **Note:** Change password after first login in production environments

### Azure Resources

**[SCREENSHOT PLACEHOLDER: Azure Portal showing resource group with all deployed resources]**

**[SCREENSHOT PLACEHOLDER: Azure Portal showing AKS cluster overview]**

**[SCREENSHOT PLACEHOLDER: Azure Portal showing running pods in AKS cluster]**

**[SCREENSHOT PLACEHOLDER: Azure Portal showing services in AKS cluster]**

**[SCREENSHOT PLACEHOLDER: Azure Portal showing public IP addresses]**

---

## Useful Commands

### Kubernetes Operations

```bash
# Get all resources in microservice namespace
kubectl get all -n microservice

# Get all resources in monitoring namespace
kubectl get all -n monitoring

# View microservice logs
kubectl logs -n microservice -l app.kubernetes.io/name=microservice --tail=50

# View Prometheus logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus --tail=50

# View Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50

# Port forward to access services locally (if needed)
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Restart deployments
kubectl rollout restart deployment/microservice-microservice -n microservice
kubectl rollout restart deployment/monitoring-grafana -n monitoring

# Check ingress configuration
kubectl get ingress -n monitoring
kubectl describe ingress monitoring-ingress -n monitoring
```

### Azure CLI Operations

```bash
# Get AKS credentials
az aks get-credentials --resource-group microservices-dev-rg --name microservices-dev-aks

# View AKS cluster info
az aks show --resource-group microservices-dev-rg --name microservices-dev-aks

# List all public IPs
az network public-ip list --resource-group microservices-dev-rg -o table
az network public-ip list --resource-group MC_microservices-dev-rg_microservices-dev-aks_eastus2 -o table

# View Load Balancer configuration
az network lb list --resource-group MC_microservices-dev-rg_microservices-dev-aks_eastus2
az network lb rule list --resource-group MC_microservices-dev-rg_microservices-dev-aks_eastus2 --lb-name kubernetes -o table

# Check NAT Gateway
az network nat gateway show --resource-group microservices-dev-rg --name microservices-dev-nat
```

---

## Project Structure

```
Microservices/
├── app/                          # Flask microservice application
│   ├── __init__.py              # Flask app initialization
│   └── requirements.txt         # Python dependencies
├── deploy/
│   ├── helm/
│   │   └── microservice/        # Helm chart for microservice
│   │       ├── Chart.yaml
│   │       ├── values.yaml      # Helm values (includes LoadBalancer config)
│   │       └── templates/
│   ├── ingress/
│   │   └── monitoring-ingress.yaml  # Ingress for Grafana/Prometheus
│   └── monitoring/
│       ├── kube-prometheus-stack-values.yaml  # Prometheus Helm values
│       └── microservice-alerts.yaml           # Custom alert rules
├── infra/
│   └── terraform/
│       ├── bootstrap/           # Bootstrap infrastructure
│       │   ├── main.tf
│       │   └── variables.tf
│       ├── main.tf              # Main infrastructure
│       ├── variables.tf
│       ├── outputs.tf
│       └── modules/
│           ├── aks/             # AKS cluster module
│           ├── network/         # VNet and subnets module
│           └── jumpbox/         # Jumpbox VM module
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD pipeline
├── Dockerfile                   # Container image definition
└── README.md                    # This file
```

---

## Technologies Used

- **Cloud Provider:** Microsoft Azure
- **Infrastructure as Code:** Terraform
- **Container Orchestration:** Kubernetes (AKS)
- **CI/CD:** GitHub Actions
- **Package Management:** Helm
- **Monitoring:** Prometheus, Grafana (kube-prometheus-stack)
- **Application Framework:** Python Flask
- **Containerization:** Docker
- **Ingress Controller:** ingress-nginx
- **Metrics Instrumentation:** prometheus-flask-exporter

---

## Future Enhancements

- [ ] Configure Alertmanager for email/Slack notifications
- [ ] Implement log aggregation with Loki
- [ ] Add horizontal pod autoscaling (HPA)
- [ ] Implement cert-manager for automatic TLS certificates
- [ ] Add Azure Key Vault integration for secrets management
- [ ] Implement network policies for enhanced security
- [ ] Configure Azure Backup for AKS
- [ ] Add cost monitoring and optimization
- [ ] Implement multi-environment deployments (dev/staging/prod)
- [ ] Add distributed tracing with Jaeger or Tempo

---

## License

[Specify your license here]

---

## Contributors

[Add contributor information]

---

## Contact

[Add contact information]
