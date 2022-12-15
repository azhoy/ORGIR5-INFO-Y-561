# NOTE: WORKING

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "mattermost_continst_id" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = azurerm_resource_group.rg.name  
    }
  byte_length = 3
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group
resource "azurerm_container_group" "mattermost_container" {
  name                = "mattermost-conti-${random_id.mattermost_continst_id.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"
  dns_name_label      = "esimattermost${random_id.mattermost_continst_id.hex}"

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
    image  = "${azurerm_container_registry.acr.login_server}/${var.mattermost_postgres_variables.container_name}:${var.mattermost_postgres_variables.image_version}"
    cpu    = "0.5"
    memory = "1.5"
    
    environment_variables = {
      "TZ"                 = var.mattermost_postgres_variables.TZ
      "POSTGRES_USER"      = var.mattermost_postgres_variables.POSTGRES_USER
      "POSTGRES_DB"        = var.mattermost_postgres_variables.POSTGRES_DB
      "POSTGRES_DATA_PATH" = var.mattermost_postgres_variables.POSTGRES_DATA_PATH
    }
    secure_environment_variables = {
      "POSTGRES_PASSWORD" = var.mattermost_postgres_variables.POSTGRES_PASSWORD
    }
    # commands = [ "value" ]
    ports {
      port     = var.mattermost_postgres_variables.port
      protocol = var.mattermost_postgres_variables.protocol
    }
    volume {
      name                 = "postgres-data"
      mount_path           = var.mattermost_postgres_variables.POSTGRES_DATA_PATH
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_share.name
    }    
  }

  container {
    name   = "mattermost"
    image  = "${azurerm_container_registry.acr.login_server}/${var.mattermost_variables.container_name}:${var.mattermost_variables.image_version}"
    cpu    = "0.5"
    memory = "1.5"
    
    environment_variables = {
      "TZ"                             = var.mattermost_variables.TZ
      "DOMAIN"                         = "esimattermost${random_id.mattermost_continst_id.hex}.westeurope.azurecontainer.io"
      "APP_PORT"                       = var.mattermost_variables.port
      "POSTGRES_USER"                  = var.mattermost_postgres_variables.POSTGRES_USER
      "POSTGRES_DB"                    = var.mattermost_postgres_variables.POSTGRES_DB
      "MATTERMOST_CONFIG_PATH"         = var.mattermost_variables.MATTERMOST_CONFIG_PATH
      "MATTERMOST_DATA_PATH"           = var.mattermost_variables.MATTERMOST_DATA_PATH
      "MATTERMOST_LOGS_PATH"           = var.mattermost_variables.MATTERMOST_LOGS_PATH
      "MATTERMOST_PLUGINS_PATH"        = var.mattermost_variables.MATTERMOST_PLUGINS_PATH
      "MATTERMOST_CLIENT_PLUGINS_PATH" = var.mattermost_variables.MATTERMOST_CLIENT_PLUGINS_PATH
      "MATTERMOST_BLEVE_INDEXES_PATH"  = var.mattermost_variables.MATTERMOST_BLEVE_INDEXES_PATH
      "MM_SQLSETTINGS_DRIVERNAME"      = "postgres"
      "MM_BLEVESETTINGS_INDEXDIR"      = var.mattermost_variables.MM_BLEVESETTINGS_INDEXDIR
      "MM_SERVICESETTINGS_SITEURL"     = "https://esimattermost${random_id.mattermost_continst_id.hex}.westeurope.azurecontainer.io"

    }
    secure_environment_variables = {
      "POSTGRES_PASSWORD"              = var.mattermost_postgres_variables.POSTGRES_PASSWORD
      "MM_SQLSETTINGS_DATASOURCE"      ="postgres://${var.mattermost_postgres_variables.POSTGRES_USER}:${var.mattermost_postgres_variables.POSTGRES_PASSWORD}@localhost:5432/${var.mattermost_postgres_variables.POSTGRES_DB}?sslmode=disable&connect_timeout=10"

    }
    #commands = [ "value" ]
    ports {
      port     = var.mattermost_variables.port
      protocol = var.mattermost_variables.protocol
    }
    volume {
      name                 = "mattermost-config-path"
      mount_path           = var.mattermost_variables.MATTERMOST_CONFIG_PATH
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_share.name
    }   
    volume {
      name                 = "mattermost-data-path"
      mount_path           = var.mattermost_variables.MATTERMOST_DATA_PATH
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_share.name
    }   
    volume {
      name                 = "mattermost-logs-path"
      mount_path           = var.mattermost_variables.MATTERMOST_LOGS_PATH
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_share.name
    }   
    volume {
      name                 = "mattermost-plugin-path"
      mount_path           = var.mattermost_variables.MATTERMOST_PLUGINS_PATH
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_share.name
    }   
    volume {
      name                 = "mattermost-client-plugin-path"
      mount_path           = var.mattermost_variables.MATTERMOST_CLIENT_PLUGINS_PATH
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_share.name
    }   
    volume {
      name                 = "mattermost-blev-path"
      mount_path           = var.mattermost_variables.MATTERMOST_BLEVE_INDEXES_PATH
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_share.name
    }   
    volume {
      name                 = "mattermost-blev-index-path"
      mount_path           = var.mattermost_variables.MM_BLEVESETTINGS_INDEXDIR
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_share.name
    }   
   
  }

  # To enable HTTPS
  container {
    name   = "caddy-mattermost"
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
      name                 = "mattermost-caddy-data"
      mount_path           = "/data"
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_mattermost_caddy_share.name
    }

    commands = [ 
      "caddy", 
      "reverse-proxy", 
      "--from", 
      "esimattermost${random_id.mattermost_continst_id.hex}.westeurope.azurecontainer.io", 
      "--to", 
      "localhost:${var.mattermost_variables.port}"
       ] # Command to reverse proxy 
  }
  

  diagnostics {
    log_analytics {
      workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.workspace_id
      workspace_key = azurerm_log_analytics_workspace.log_analytics_workspace.primary_shared_key
    }
  } 
}

