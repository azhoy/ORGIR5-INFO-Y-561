# Infrastructure

## 0. Prepare the environment

0. Install Terraform & Azure CLI

1. Subscribe to Azure for Students
[Azure for Students](https://azure.microsoft.com/en-us/free/students/)

2. Connect to Azure CLI
```Shell
az login
```

3. Check the active subscription (Switch to *Azure for students*)
```Shell
az account show --output table
```

- If name is not "Azure for Students"
```Shell
az account set --subscription "Azure for Students"
```

5. [Configure  Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell-bash?tabs=bash) with CLI (with **Onwer role** not Contributor !!)
   
6. Increase Terraform service special permissions

- Azure portal >> <ServiceSpecialName> (Terraform) >> permissions >> Add permissions and grant admin consent

![Step 1](/images/1A.png "Step 1")

## 1. Store state file on Azure

1. Use [custom script](bin/NewStateFileStorage.sh) to create a new resources group, storage account and container to store the terraform state files on Azure

2. Modify the [apply pipeline](azure-pipelines.yml) and [destroy pipeline](azure-pipeline-destroy.yml) files

```Shell

backendServiceArm: '<SubscriptionName(ID)>' 
backendAzureRmResourceGroupName: '<ResourceGroupName>'
backendAzureRmStorageAccountName: '<StorageAccountName>'
backendAzureRmContainerName: '<ContainerName>'
backendAzureRmKey: '<environmentName>/terraform.tfstate' # Not from CLI, Choose where to store on container

```

3. Modify the [provider terraform](provider.tf) file with the correct storage account values

```HCL
terraform {
  required_version = "~>1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.29.0"
    }
  }   
    backend "azurerm" {
        resource_group_name  = "<ResourceGroupName>"
        storage_account_name = "<StorageAccountName>"
        container_name       = "<ContainerName>"
        key                  = "<environmentName>/terraform.tfstate"
    }
}
```

## 2. Creates an Azure Container Registry

1. Use [custom script](bin/CreatesContainerRegistry.sh) to creates a container registry

2. Pull or create docker images

3. Push images to the registry
   
4. Import the container registry to the terraform state file
- Write in [import.tf](import.tf)
```
resource "azurerm_container_registry" "acr" {}
```
- Use [custom script](bin/ImportACR.sh)
- Run the commande
```
terraform state show azurerm_container_registry.acr
```
- Copy the line location, name, resource_group_name, sku and set admin_enabled to true *"azurerm_container_registry" "acr"* in the [import file](import.tf)

```
resource "azurerm_container_registry" "acr" {
    location                      = <location>
    name                          = <ACRName> 
    resource_group_name           = <resourceGroup> 
    sku                           = "Basic" 
    admin_enabled                 = true
}
```


## 3. Create an Azure DevOps Pipeline

1. See [video](https://www.youtube.com/watch?v=d85-KD9stqc&list=PLOX-vE9cPhaewlwnkcyJbM53guELOue-B&index=1)

## 4. Add permissions to the Pipeline services special for Azure AD

1. Organization Settings >> Service connections >> SubscriptionName >> Manage Service Special
![Step 1](/images/4A.png "Step 1")
![Step 2](/images/4B.png "Step 2")

2. Add permissions >> Microsoft Graph >> Application Permission >> Grant admin consent for Default directory
![Step 3](/images/4C.png "Step 3")
![Step 4](/images/4D.png "Step 4")


### **Remark:**
**Always** check if the container registry is in the state file before running an execution
```
terraform state list | grep "azurerm_container_registry.acr"
```
**OR**
```
terraform state show azurerm_container_registry.acr
```