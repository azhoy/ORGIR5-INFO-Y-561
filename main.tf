#####################################################################################################
############################################ @ PROVIDER ############################################
#####################################################################################################

terraform {
  required_version = "~>1.3"

  required_providers {

    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.30.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.29.0"
    }
  } 
    # Store state file on Azure in README file 
    backend "azurerm" {
        resource_group_name  = "<resourceGroupName>"
        storage_account_name = "<storageAccountName>"
        container_name       = "<containerName>"
        key                  = "dev/terraform.tfstate"
    }
    
}

# Get subscription data
data "azurerm_subscription" "primary" {
}

# Get cliend data
data "azurerm_client_config" "current" {
}

# Azure Active Directory provider
provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

#####################################################################################################
############################################ @ GENRAL & AD ############################################
#####################################################################################################

# % Creates a resources group

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "resource_group_id" {
  byte_length = 3
}

resource "azurerm_resource_group" "rg" {
  name     = "orga-rg-${random_id.resource_group_id.hex}"
  location = var.location
} 

# % Azure AD
# Access information about existing Domains within Azure Active Directory.
# requires one of the following application roles: Domain.Read.All or Directory.Read.All
# For Azure DevOps or Terraform (README)

# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/domains
data "azuread_domains" "default_domain" {
  only_initial = true
}

locals {
  domain_name = data.azuread_domains.default_domain.domains.0.domain_name
  users       = csvdecode(file("${path.module}/${var.csv_users_file}"))
}

resource "random_pet" "user_suffix" {
  length = 2
}

# Manages a user within Azure Active Directory.
# requires one of the following application roles: User.ReadWrite.All or Directory.ReadWrite.All
# For Azure DevOps or Terraform (README)

# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/user
resource "azuread_user" "users" {
  for_each = { for user in local.users : user.first_name => user }

  user_principal_name = format(
    "%s%s-%s@%s",
    substr(lower(each.value.first_name), 0, 1),
    lower(each.value.last_name),
    random_pet.user_suffix.id,
    local.domain_name
  )

  password = format(
    "%s%s%s!",
    lower(each.value.last_name),
    substr(lower(each.value.first_name), 0, 1),
    length(each.value.first_name)
  )
  force_password_change = true

  display_name = "${each.value.first_name} ${each.value.last_name}"
  department   = each.value.department
  job_title    = each.value.job_title
}

# Verify users creation on CLI
# az ad user list --output tsv


#####################################################################################################
############################################ @ NETWORKING ############################################
#####################################################################################################

# % VNET
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "services_network" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = var.services_vnet.name
  address_space       = var.services_vnet.address_space
}

# NOTE: Keycloak not implement
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "keycloak_subnet" {
  name                                           = var.keycloak_subnet.name
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.services_network.name
  address_prefixes                               = var.keycloak_subnet.address_prefixes
  private_endpoint_network_policies_enabled      = var.keycloak_subnet.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled  = var.keycloak_subnet.private_link_service_network_policies_enabled

}


#####################################################################################################
############################################ @ MONITORING ############################################
#####################################################################################################

#=====
# Log analytics
#=====

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "log_analytics_workspace_id" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = azurerm_resource_group.rg.name  
    }
  byte_length = 3
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "orga-log-ws-${random_id.log_analytics_workspace_id.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_solution
resource "azurerm_log_analytics_solution" "log_analytics_solution" {
    for_each = var.log_analytics_solution_plan_map

  solution_name         = each.key
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
  workspace_name        = azurerm_log_analytics_workspace.log_analytics_workspace.name

  plan {
    product   = each.value.product
    publisher = each.value.publisher
  }
}


/*
# Diagnostics settings

resource "azurerm_monitor_diagnostic_setting" "services_network_diagnostics_settings" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = azurerm_virtual_network.services_network.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  log {
    category = "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.log_analytics_workspace.retention_in_days
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = azurerm_log_analytics_workspace.log_analytics_workspace.retention_in_days
    }
  }
}
*/



# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group
resource "azurerm_monitor_action_group" "action_group" {
  name                = var.action_group_variables.action_group_name
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = var.action_group_variables.action_group_shortname

    email_receiver {
    name                    = var.action_group_variables.email_receiver_name
    email_address           = var.action_group_variables.email_address
    use_common_alert_schema = true
  }
}

#=====
# Containers Resources Usage Montioring groups
#====

# 1) Mattermost Meet Container Group 

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert

# CPU
resource "azurerm_monitor_metric_alert" "mattermost_cpu_alert" {
  name                = "mattermost-cpu"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.mattermost_container.id]
  description         = "Action will be triggered when CPU Usage is greater than 90%."

  criteria {
    metric_namespace = "Microsoft.ContainerInstance/containerGroups"
    metric_name      = "CpuUsage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

# Memory
resource "azurerm_monitor_metric_alert" "mattermost_memory_alert" {
  name                = "mattermost-memory"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.mattermost_container.id]
  description         = "Action will be triggered when Memory Usage is greater than 90%."

  criteria {
    metric_namespace = "Microsoft.ContainerInstance/containerGroups"
    metric_name      = "MemoryUsage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}
# Jitsi
# Resources health
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert
resource "azurerm_monitor_activity_log_alert" "mattermost_resource_health" {
  name                = "mattermost-resource-health"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.mattermost_container.id]
  description         = "Action will be triggered when resource health changes."

  criteria {
    category = "ResourceHealth"
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert

# CPU
resource "azurerm_monitor_metric_alert" "jitsi_cpu_alert" {
  name                = "jitsi-cpu"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.jitsi_container.id]
  description         = "Action will be triggered when CPU Usage is greater than 90%."

  criteria {
    metric_namespace = "Microsoft.ContainerInstance/containerGroups"
    metric_name      = "CpuUsage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

# Memory
resource "azurerm_monitor_metric_alert" "jitsi_memory_alert" {
  name                = "jitsi-memory"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.jitsi_container.id]
  description         = "Action will be triggered when Memory Usage is greater than 90%."

  criteria {
    metric_namespace = "Microsoft.ContainerInstance/containerGroups"
    metric_name      = "MemoryUsage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

# Resources health
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert
resource "azurerm_monitor_activity_log_alert" "jitsi_resource_health" {
  name                = "jitsi-resource-health"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.jitsi_container.id]
  description         = "Action will be triggered when resource health changes."

  criteria {
    category = "ResourceHealth"
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}


#  Nextcloud Container Group 

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert

# CPU
resource "azurerm_monitor_metric_alert" "nextcloud_cpu_alert" {
  name                = "nextcloud-cpu"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.nextcloud_container.id]
  description         = "Action will be triggered when CPU Usage is greater than 90%."

  criteria {
    metric_namespace = "Microsoft.ContainerInstance/containerGroups"
    metric_name      = "CpuUsage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

# Memory
resource "azurerm_monitor_metric_alert" "nextcloud_memory_alert" {
  name                = "nextcloud-memory"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.nextcloud_container.id]
  description         = "Action will be triggered when Memory Usage is greater than 90%."

  criteria {
    metric_namespace = "Microsoft.ContainerInstance/containerGroups"
    metric_name      = "MemoryUsage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

# Resources health
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert
resource "azurerm_monitor_activity_log_alert" "nextcloud_resource_health" {
  name                = "nextcloud-resource-health"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_container_group.nextcloud_container.id]
  description         = "Action will be triggered when resource health changes."

  criteria {
    category = "ResourceHealth"
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}


#####################################################################################################
############################################ @ STORAGE ############################################
#####################################################################################################


# Containers Storage accounts

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "storage_account_cont_id" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = azurerm_resource_group.rg.name  
    }
  byte_length = 2
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "azurerm_storage_account" "storage_account_cont" {
  name                     = "esistorage${random_id.storage_account_cont_id.hex}" # Must be unique within Azure
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = var.storage_account_kind
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  enable_https_traffic_only = true


  network_rules {
    default_action             = (length(var.storage_account_ip_rules) + length(var.storage_account_virtual_network_subnet_ids)) > 0 ? "Deny" : var.storage_account_default_action
    ip_rules                   = var.storage_account_ip_rules
    virtual_network_subnet_ids = var.storage_account_virtual_network_subnet_ids
  }

  identity {
    type = "SystemAssigned"
  }
}

# Share available storage with containers

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share
resource "azurerm_storage_share" "aci_mattermost_share" {
  name                 = "mattermost-data"
  storage_account_name = azurerm_storage_account.storage_account_cont.name
  quota                = 30
}

# Store caddy generated certificates for the mattermost instancecertificates
resource "azurerm_storage_share" "aci_mattermost_caddy_share" {
  name                 = "caddy-mattermost-data"
  storage_account_name = azurerm_storage_account.storage_account_cont.name
  quota                = 2
}
resource "azurerm_storage_share" "aci_nextcloud_share" {
  name                 = "nextcloud-data"
  storage_account_name = azurerm_storage_account.storage_account_cont.name
  quota                = 30
}
resource "azurerm_storage_share" "aci_nextcloud_caddy_share" {
  name                 = "caddy-nextcloud-data"
  storage_account_name = azurerm_storage_account.storage_account_cont.name
  quota                = 2
}
resource "azurerm_storage_share" "aci_jitsi_meet_share" {
  name                 = "jitsi-data"
  storage_account_name = azurerm_storage_account.storage_account_cont.name
  quota                = 30
}



#####################################################################################################
############################################ @ Key Vault ############################################
#####################################################################################################
# NOTE: We didn't use it in the end
/*
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "key_vault_id" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = azurerm_resource_group.rg.name  
    }
  byte_length = 3
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault
resource "azurerm_key_vault" "key_vault" {
  name                            = "orgaKeyVault${random_id.key_vault_id.hex}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.key_vault_sku_name
  enabled_for_deployment          = var.key_vault_enabled_for_deployment
  enabled_for_disk_encryption     = var.key_vault_enabled_for_disk_encryption
  enabled_for_template_deployment = var.key_vault_enabled_for_template_deployment
  enable_rbac_authorization       = var.key_vault_enable_rbac_authorization
  purge_protection_enabled        = var.key_vault_purge_protection_enabled
  soft_delete_retention_days      = var.key_vault_soft_delete_retention_days
  
  network_acls {
    bypass                     = var.key_vault_bypass
    default_action             = var.key_vault_default_action
    ip_rules                   = var.key_vault_ip_rules
    virtual_network_subnet_ids = var.key_vault_virtual_network_subnet_ids
  }
}
*/
