## Terraform Architecture

The infrastructure code is organised as reusable modules that are wired together by an environment-level root module.

- `modules/network` provisions a virtual network, dedicated subnets for AKS nodes, the ACR private endpoint, and a management subnet for the jump host.
- `modules/acr` creates an Azure Container Registry, registers the AKS cluster as a pull principal, and outputs the registry login server.
- `modules/aks` provisions an AKS private cluster with one system node pool and an optional user node pool. It integrates with ACR and the virtual network.
- `modules/jumpbox` builds a small Linux VM (Bastion host) inside the management subnet, exposing SSH only via an Azure public IP for cluster administration.

Each environment (for example `environments/dev`) consumes these modules and manages remote state, providers, and shared variables.

> All modules will expose inputs for naming, sizing, and networking so additional environments (e.g., staging, prod) can be added by creating new folders under `environments/`.
