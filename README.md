<div align="center">
  <h1 style="color: red;"> Microservices Deployment on Azure Kubernetes Service (AKS)</h1>
</div>

A fully automated, production-grade microservices deployment architecture for Azure Kubernetes Service (AKS), built with Terraform, Helm, and GitHub Actions, providing scalable infrastructure, continuous delivery, and complete observability through Prometheus and Grafana.

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

3. **Apply bootstrap configuration**
   ```bash
   terraform apply
   ```

   <img width="886" height="229" alt="tfstate" src="https://github.com/user-attachments/assets/650062d3-d3e3-4afb-9ff3-b6ad00aba9f2" />

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

3. **Apply infrastructure configuration**
   ```bash
   terraform apply
   ```

   <img width="1321" height="278" alt="terraform apply" src="https://github.com/user-attachments/assets/f9a4e4be-dc44-4464-a20c-dad228b94467" />



#### Infrastructure Resources Created:
- **Virtual Network** with subnets for AKS and Jumpbox
- **AKS Cluster** (microservices-dev-aks)
- **NAT Gateway** for AKS egress traffic (uses 1 public IP)
- **Jumpbox VM** for cluster access (public IP will be detached later)
- **Network Security Groups** with appropriate rules
- **3 Public IP addresses** (NAT Gateway, Microservice LoadBalancer, Monitoring Ingress)
- **Azure Container Registry** 
---

## Jumpbox Configuration

After infrastructure deployment, configure the Jumpbox to access the AKS cluster.

#### Steps:

1. **SSH into Jumpbox** (while it still has public IP)
   ```bash
   ssh azureuser@<JUMPBOX_PUBLIC_IP>
   ```

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

   Install Helm 3:
   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

3. **Authenticate with Azure and get AKS credentials**
   ```bash
   az login

   az aks get-credentials \
     --resource-group microservices-dev-rg \
     --name microservices-dev-aks
   ```

   <img width="1395" height="533" alt="az-login" src="https://github.com/user-attachments/assets/1dda80ef-257c-413e-bba9-046368b4fece" />

5. **Verify cluster access**
   ```bash
   kubectl get nodes
   ```

6. **Check pods across all namespaces**
   ```bash
   kubectl get pods -A
   ```

   <img width="866" height="347" alt="K8s-jumpbox2" src="https://github.com/user-attachments/assets/71384943-7d97-4653-ab55-0a02db502e3b" />


7. **Verify services**
   ```bash
   kubectl get svc --all-namespaces
   ```

   <img width="1579" height="365" alt="svc-output" src="https://github.com/user-attachments/assets/89b99990-e159-4e69-9b0a-b309f02fbd15" />


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

   <img width="1689" height="862" alt="self-hosted" src="https://github.com/user-attachments/assets/37f7e1f7-e308-4694-9313-ceab55f22917" />

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

4. **Verify runner is online**
   - Navigate to GitHub repository → Settings → Actions → Runners

   <img width="1500" height="461" alt="runners" src="https://github.com/user-attachments/assets/595dce92-f5e3-462a-8204-4e900228e247" />

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

4. **Add additional secrets** (if needed)
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `AZURE_TENANT_ID`: Your Azure tenant ID
   - Any other sensitive values used in the workflow

     <img width="1414" height="525" alt="secrets" src="https://github.com/user-attachments/assets/a7511649-7613-4270-becc-e3709a79775a" />

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

   <img width="1895" height="577" alt="pipeline" src="https://github.com/user-attachments/assets/bd7d6f28-c0cc-4dca-968e-56e531490be7" />

### Verify Deployment

**Check deployed pods:**
```bash
kubectl get pods -n microservice
```

<img width="881" height="71" alt="pod-microservice" src="https://github.com/user-attachments/assets/0788cfad-7858-4ae4-8307-d3e416e87f30" />

**Check services:**
```bash
kubectl get svc -n microservice
```

<img width="1112" height="47" alt="svc-microservice" src="https://github.com/user-attachments/assets/1ee8b229-2b98-43df-a029-ce2a4226e8e3" />

#### Access Microservice App UI:

- URL: `http://132.196.184.141/users/1` or `http://132.196.184.141/products/1` 
- Access via browser

  <img width="1172" height="215" alt="app-ui" src="https://github.com/user-attachments/assets/f1a35ff5-d7f6-42c8-9de8-89ebf6ac4f23" />

  <img width="752" height="204" alt="app-ui2" src="https://github.com/user-attachments/assets/f450ddd0-5574-44d1-acd2-bf82c7d106ef" />

---

## Monitoring Setup

### Prometheus

Prometheus is deployed using the kube-prometheus-stack Helm chart for metrics collection and monitoring.

#### Verify Prometheus Deployment:

```bash
kubectl get pods -n monitoring | grep prometheus
kubectl get svc -n monitoring | grep prometheus
```

<img width="1112" height="145" alt="prometheus-svc-pod" src="https://github.com/user-attachments/assets/5c92054a-a248-47f6-bb88-8dafacec5368" />


#### Access Prometheus UI:

- URL: `http://20.1.152.210/prometheus`
- Access via browser

<img width="1904" height="943" alt="prometheus-UI" src="https://github.com/user-attachments/assets/22fae2c0-4e91-42ea-94ad-99e608522f1a" />

<img width="1899" height="962" alt="prometheus-UI-2" src="https://github.com/user-attachments/assets/7d2867ab-04fc-4b2b-9c84-77dacc882c3b" />

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

<img width="1095" height="48" alt="grafana-svc-pod" src="https://github.com/user-attachments/assets/29fb473f-55c4-4eee-83a8-1efa258a7b97" />

#### Access Grafana UI:

- URL: `http://20.1.152.210/grafana`
- Default credentials: `admin` / `changeme`


#### Configure Prometheus Datasource:

1. Navigate to Configuration → Data Sources → Add data source
2. Select Prometheus
3. URL: `http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/prometheus`
4. Click "Save & Test"


#### Import Kubernetes Dashboards:

**Dashboard IDs:**
- **15661** - Kubernetes Cluster Monitoring
- **6417** - Kubernetes Cluster Overview

<img width="1913" height="883" alt="Grafana-UI" src="https://github.com/user-attachments/assets/6fcd1353-bc0e-4a8d-8511-81398dccf115" />

<img width="1919" height="826" alt="grafana-UI-2" src="https://github.com/user-attachments/assets/da149029-64f2-4be8-935d-becd60e01160" />

<img width="1912" height="866" alt="grafana-ui-3" src="https://github.com/user-attachments/assets/37dca043-a271-4423-8583-3c9b869c3a24" />

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

### Grafana Credentials

- **Username:** `admin`
- **Password:** `changeme`
- **Note:** Change password after first login in production environments

### Azure Resources

<img width="1899" height="590" alt="RG-UI" src="https://github.com/user-attachments/assets/43903516-2828-4eb9-bcd5-427f9a7305b1" />

<img width="1881" height="790" alt="aks-ui" src="https://github.com/user-attachments/assets/f42bcb4d-dc81-428f-90a4-e750d7ce483c" />

<img width="1866" height="732" alt="pods-ui" src="https://github.com/user-attachments/assets/6b7dda27-da25-46c3-bab2-05543ac05e84" />

<img width="1845" height="765" alt="svc-ui" src="https://github.com/user-attachments/assets/0d5b3028-573c-48b8-ac31-9e38a39b82dd" />

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
│       └── kube-prometheus-stack-values.yaml  # Prometheus Helm values
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




