#!/bin/zsh

# NOTE: Working
# Import the Azure Container Registry that was created by a script
# to the terraform state file to be able to use it with terraform

# Resource 
# https://developer.hashicorp.com/terraform/cli/commands/import
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry#import

ACR_SERVER_ID=<ACR_ID> # Fetched form Azure CLI or on Azure Portal

cd .. 
terraform init -upgrade
terraform import azurerm_container_registry.acr $ACR_SERVER_ID