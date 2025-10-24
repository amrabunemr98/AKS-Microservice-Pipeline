variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name used as a prefix for resources."
  type        = string
  default     = "microservices"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, stage, prod)."
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "CIDR ranges for the virtual network."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "CIDR for the AKS subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "acr_subnet_prefix" {
  description = "CIDR for the subnet hosting private endpoints."
  type        = string
  default     = "10.10.2.0/28"
}

variable "jumpbox_subnet_prefix" {
  description = "CIDR for the management jumpbox subnet."
  type        = string
  default     = "10.10.3.0/28"
}

variable "enable_nat_gateway" {
  description = "Provision a NAT gateway for outbound Internet access."
  type        = bool
  default     = true
}

variable "create_aks_nsg" {
  description = "Create and associate an NSG with the AKS subnet."
  type        = bool
  default     = true
}

variable "private_cluster_enabled" {
  description = "Whether the AKS API server should be private."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Optional Kubernetes version override."
  type        = string
  default     = ""
}

variable "node_count" {
  description = "Number of nodes in the system node pool."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for AKS nodes."
  type        = string
  default     = "Standard_DS2_v2"
}

variable "user_node_pool_enabled" {
  description = "Whether to create an additional user node pool for workloads."
  type        = bool
  default     = false
}

variable "user_node_pool_vm_size" {
  description = "VM size for the user node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "user_node_pool_node_count" {
  description = "Node count for the user node pool."
  type        = number
  default     = 1
}

variable "grafana_allowed_cidr" {
  description = "CIDR block allowed to access Grafana."
  type        = string
  default     = "0.0.0.0/0"
}

variable "prometheus_allowed_cidr" {
  description = "CIDR block allowed to access Prometheus."
  type        = string
  default     = "0.0.0.0/0"
}

variable "acr_sku" {
  description = "SKU for the Azure Container Registry."
  type        = string
  default     = "Standard"
}

variable "acr_private_endpoint_enabled" {
  description = "Whether to create a private endpoint for ACR (requires Premium SKU)."
  type        = bool
  default     = false
}

variable "jumpbox_admin_username" {
  description = "Admin username for the jumpbox VM."
  type        = string
  default     = "azureuser"
}

variable "jumpbox_vm_size" {
  description = "VM size for the jumpbox."
  type        = string
  default     = "Standard_B2s"
}

variable "ssh_public_key_path" {
  description = "Local filesystem path to the SSH public key used for the jumpbox."
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to access the jumpbox over SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    workload = "microservices"
  }
}
