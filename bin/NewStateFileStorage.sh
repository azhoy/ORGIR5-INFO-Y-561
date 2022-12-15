#!/bin/zsh

# NOTE: Working

# Create a storage account on Azure to store the Terraform state file on the Cloud
# It enables enable cooperative terraform programming with the storage account access key

RESOURCE_GROUP_NAME=<resourceGroupName>
STORAGE_ACCOUNT_NAME=<storageAccountName>$RANDOM
CONTAINER_NAME=<containerName>

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location westeurope

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

#Get the storage access key and store it as an environment variable
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
export ARM_ACCESS_KEY=$ACCOUNT_KEY

# Write the created storage account data onto the pipeline and terraform file to connect to it when the 'terraform init' command is launched