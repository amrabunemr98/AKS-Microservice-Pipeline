variable "resource_group_name" {
  description = "Resource group for the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix used for the AKS API server."
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to deploy. Leave empty to use the latest default."
  type        = string
  default     = ""
}

variable "node_count" {
  description = "Number of nodes in the default system node pool."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for the default node pool."
  type        = string
  default     = "Standard_DS2_v2"
}

variable "aks_subnet_id" {
  description = "Subnet ID used for the AKS node pool."
  type        = string
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry for image pulls."
  type        = string
}

variable "authorized_ip_ranges" {
  description = "List of public CIDR ranges that can reach the API server when private cluster is disabled."
  type        = list(string)
  default     = []
}

variable "private_cluster_enabled" {
  description = "Whether the AKS control plane should be private."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply."
  type        = map(string)
  default     = {}
}
