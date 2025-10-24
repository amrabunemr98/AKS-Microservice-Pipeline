## Remote State Setup (Azure Storage)

The Terraform backend is configured to use an Azure Storage account. Run these steps before `terraform init` so Terraform can store state remotely:

1. Select the correct subscription (if required):
   ```bash
   az account set --subscription "<subscription-id>"
   ```

2. Create the resource group for state:
   ```bash
   az group create --name tfstate-rg --location eastus
   ```

3. Create a (globally unique) storage account:
   ```bash
   az storage account create \
     --name tfstateacct00123 \
     --resource-group tfstate-rg \
     --location eastus \
     --sku Standard_LRS \
     --encryption-services blob \
     --allow-blob-public-access false
   ```

4. Create the blob container that will hold the state file:
   ```bash
   az storage container create \
     --name tfstate \
     --account-name tfstateacct00123 \
     --auth-mode login
   ```

5. Authenticate Terraform:
   - Option A (quick start): export an access key so the backend can authenticate:
     ```bash
     export ARM_ACCESS_KEY=$(az storage account keys list \
       --resource-group tfstate-rg \
       --account-name tfstateacct00123 \
       --query '[0].value' -o tsv)
     ```

   - Option B (recommended): use Azure AD data-plane auth by granting yourself Storage Blob Data Contributor on the storage account after registering the Microsoft.Storage provider.

6. Generate an SSH key pair (if you do not already have one) and point `ssh_public_key_path` at it in `terraform.tfvars`:
  ```bash
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_azure -C "aks-admin"
  cat ~/.ssh/id_rsa_azure.pub
  ```
   Save the public key to a path (e.g. `~/.ssh/id_rsa_azure.pub`) and set `ssh_public_key_path = "~/.ssh/id_rsa_azure.pub"` in `terraform.tfvars`. You can also adjust other inputs such as `node_vm_size`, `jumpbox_vm_size`, `acr_sku`, and `acr_private_endpoint_enabled` to match the SKUs available in your subscription (ACR private endpoints require the Premium SKU).

7. Initialise Terraform with the backend configuration:
   ```bash
   terraform init \
     -backend-config="resource_group_name=tfstate-rg" \
     -backend-config="storage_account_name=tfstateacct00123" \
     -backend-config="container_name=tfstate" \
     -backend-config="key=microservices-dev.tfstate"
   ```

Once initialised, manage infrastructure as usual with `terraform plan` and `terraform apply`. Keep the names in `provider.tf` in sync with the resources you created.



Terraform just created the ACR, but the service principal/user running Terraform doesn’t have rights to assign roles at the registry. Fix it by granting yourself permission, then re-run apply.
az role assignment create \
  --assignee bad6e5fa-3d8e-4ee8-981e-bf3d4b124092 \
  --role "Owner" \
  --scope /subscriptions/ea26b3d8-d191-4a12-910c-cac840178587/resourceGroups/microservices-dev-rg



Make sure your local IP is within allowed_ssh_cidrs :
curl ifconfig.me  Suppose it returns your ip
then update your allowed_ssh_cidrs = ["your ip /32"]


after apply:
ssh -i ~/.ssh/id_rsa_azure abunemr@20.7.10.13
then : Log in to Azure from the jumpbox
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
[to install azure cli ]

then 

az login --use-device-code
az account set --subscription ea26b3d8-d191-4a12-910c-cac840178587
to can add aks cred. in jumpbox

then:
install kubectl in jumpbox:

# Install kubectl (latest stable)
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER


curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"



# Move it into PATH and make it executable
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client

Fetch AKS credentials on the jumpbox

az aks get-credentials \
  --resource-group microservices-dev-rg \
  --name microservices-dev-aks
Verify the cluster

kubectl get nodes
kubectl get pods -A



2gj8Q~YJF5a~NyYVkYLYSH7Xm~wWAi6amENFJaP~

Create an Azure service principal for the workflow :
az ad sp create-for-rbac \
  --name microservices-actions \
  --role Contributor \
  --scopes /subscriptions/ea26b3d8-d191-4a12-910c-cac840178587 \
  --sdk-auth
will add jason in secrets of github actions


selfhosted runner after running command so must Install and start as a service so it survives reboots:

sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh statu