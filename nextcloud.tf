# NOTE: Dockers run HTTPS issues

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "nextcloud_continst_id" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = azurerm_resource_group.rg.name  
    }
  byte_length = 3
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group
resource "azurerm_container_group" "nextcloud_container" {
  name                = "nextcloud-conti-${random_id.nextcloud_continst_id.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"
  dns_name_label      = "esinextcloud${random_id.nextcloud_continst_id.hex}"

  image_registry_credential {
    # !!! Check if admin_enable is set to true for the ACR on Azure Portal or Azure CLI
    server   = azurerm_container_registry.acr.login_server 
    username = azurerm_container_registry.acr.admin_username 
    password = azurerm_container_registry.acr.admin_password 
  }
  # Caddy exposed ports
  exposed_port = [ 
    {
    port     = 80
    protocol = "TCP"
    },
    {
    port     = 443
    protocol = "TCP"
    }
   ]
  
  container {
    name   = "postgres"
    image  = "${azurerm_container_registry.acr.login_server}/${var.nextcloud_postgres_variables.container_name}:${var.nextcloud_postgres_variables.image_version}"
    cpu    = "0.5"
    memory = "1.5"
    
    environment_variables = {
      "TZ"                 = var.nextcloud_postgres_variables.TZ
      "POSTGRES_USER"      = var.nextcloud_postgres_variables.POSTGRES_USER
      "POSTGRES_DB"        = var.nextcloud_postgres_variables.POSTGRES_DB
      "POSTGRES_DATA_PATH" = var.nextcloud_postgres_variables.POSTGRES_DATA_PATH
    }
    secure_environment_variables = {
      "POSTGRES_PASSWORD" = var.nextcloud_postgres_variables.POSTGRES_PASSWORD
    }
    # commands = [ "value" ]
    ports {
      port     = var.nextcloud_postgres_variables.port
      protocol = var.nextcloud_postgres_variables.protocol
    }
    volume {
      name                 = "postgres-data"
      mount_path           = var.nextcloud_postgres_variables.POSTGRES_DATA_PATH
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_nextcloud_share.name
    }    
  }
  container {
    name   = "redis"
    image  = "${azurerm_container_registry.acr.login_server}/all/redis:v1"
    cpu    = "0.5"
    memory = "1.5"
  }

  container {
    name   = "nextcloud"
    image  = "${azurerm_container_registry.acr.login_server}/${var.nextcloud_variables.container_name}:${var.nextcloud_variables.image_version}"
    cpu    = "0.5"
    memory = "1.5"
    
    environment_variables = {
      "POSTGRES_USER"      = var.nextcloud_postgres_variables.POSTGRES_USER
      "POSTGRES_DB"     = var.nextcloud_postgres_variables.POSTGRES_DB
      "POSTGRES_HOST"  = var.nextcloud_variables.POSTGRES_HOST
      "REDIS_HOST"     = var.nextcloud_variables.REDIS_HOST

    }
    secure_environment_variables = {
      "POSTGRES_PASSWORD"  = var.nextcloud_postgres_variables.POSTGRES_PASSWORD
    }
    #commands = [ "value" ]
    ports {
      port     = var.nextcloud_variables.port
      protocol = var.nextcloud_variables.protocol
    }
   
  }
  container {
    name   = "caddy-nextcloud"
    image  = "${azurerm_container_registry.acr.login_server}/${var.caddy_variables.container_name}:${var.caddy_variables.image_version}"
    cpu    = "0.5"
    memory = "1.5"
    ports {
      port     = 80
      protocol = "TCP"
    }
    ports {
      port     = 443
      protocol = "TCP"
    }
    volume {
      name                 = "nextcloud-caddy-data"
      mount_path           = "/data"
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_nextcloud_caddy_share.name
    }

    commands = [ 
      "caddy", 
      "reverse-proxy", 
      "--from", 
      "esinextcloud${random_id.nextcloud_continst_id.hex}.westeurope.azurecontainer.io", 
      "--to", 
      "localhost:${var.nextcloud_variables.port}" # 
       ] # Command to reverse proxy 
  }
  diagnostics {
    log_analytics {
      workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.workspace_id
      workspace_key = azurerm_log_analytics_workspace.log_analytics_workspace.primary_shared_key
    }
  } 
}
