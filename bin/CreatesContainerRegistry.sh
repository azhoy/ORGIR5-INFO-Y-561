#!/bin/zsh

# NOTE: Working
# Create a private registry on Azure to store docker images

# 1. Connect to azure CLI
# 2. Install docker and docker-compose

RESOURCE_GROUP_NAME=acrRG01
CONTAINER_REGISTERY_NAME=<registryName>$RANDOM

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location westeurope

# Create a container registry
az acr create --resource-group $RESOURCE_GROUP_NAME --name $CONTAINER_REGISTERY_NAME --sku Basic --admin-enabled true

# Log in to registry
az acr login --name $CONTAINER_REGISTERY_NAME

LOGIN_ACR_SERVER=$(az acr show -n $CONTAINER_REGISTERY_NAME --query loginServer -o tsv)

# Pull an existing public image

# Tag the image
#docker tag <imageID> $LOGIN_ACR_SERVER/<conatinerName>:<version>

# Push the image to the azure private registry 
#docker push $LOGIN_ACR_SERVER/<conatinerName>:<version>

# /!\ Store images by group

