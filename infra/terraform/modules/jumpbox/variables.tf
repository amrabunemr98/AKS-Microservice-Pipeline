variable "resource_group_name" {
  description = "Resource group for the jumpbox VM."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vm_name" {
  description = "Name of the jumpbox virtual machine."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the jumpbox NIC will reside."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for administrator access."
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR ranges allowed to SSH into the jumpbox."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vm_size" {
  description = "VM size for the jumpbox."
  type        = string
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB."
  type        = number
  default     = 64
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
