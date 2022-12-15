# NOTE: Dockers run with HTTPS issues

# Resources 
# https://hub.docker.com/u/jitsi
# https://github.com/jitsi/docker-jitsi-meet
# https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker/

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "jitsi_continst_id" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = azurerm_resource_group.rg.name  
    }
  byte_length = 3
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group
resource "azurerm_container_group" "jitsi_container" {
  name                = "jitsi-conti-${random_id.jitsi_continst_id.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"
  dns_name_label      = "esijitsi${random_id.jitsi_continst_id.hex}"

  image_registry_credential {
    # !!! Check if admin_enable is set to true for the ACR on Azure Portal or Azure CLI
    server   = azurerm_container_registry.acr.login_server 
    username = azurerm_container_registry.acr.admin_username 
    password = azurerm_container_registry.acr.admin_password 
  }
  # Jitsi Web exposed ports
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
    name   = "web"
    image  = "${azurerm_container_registry.acr.login_server}/jitsi/web:v1" # NOTE: To be changed according to the private registry images name
    cpu    = "0.5"
    memory = "1.5"
    
    environment_variables = {
      "HTTP_PORT" = 80
      "HTTPS_PORT" =  443
      "CONFIG" = "/opt/jitsi-meet-cfg"
      "TZ" = "Europe/Brussels"
      "PUBLIC_URL" = "https://esijitsi${random_id.jitsi_continst_id.hex}.westeurope.azurecontainer.io"
      "ENABLE_LETSENCRYPT" = 1
      "LETSENCRYPT_DOMAIN" = "esijitsi${random_id.jitsi_continst_id.hex}.westeurope.azurecontainer.io"
      "LETSENCRYPT_EMAIL" = "<adminMail>"
      "LETSENCRYPT_USE_STAGING" = 1
      "ENABLE_HTTP_REDIRECT" = 1
    }

    #commands = [ "value" ]
    ports {
      port     = 80
      protocol = "TCP"
    }
    ports {
      port     = 443
      protocol = "TCP"
    }
    volume {
      name                 = "jitsi-config-web-path"
      mount_path           = "/opt/jitsi-meet-cfg/web"
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_jitsi_meet_share.name
    }   
    volume {
      name                 = "jitsi-config-cron-path"
      mount_path           = "/opt/jitsi-meet-cfg/web/crontabs"
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_jitsi_meet_share.name
    }      
    volume {
      name                 = "jitsi-config-transcripts-path"
      mount_path           = "/opt/jitsi-meet-cfg/transcripts"
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_jitsi_meet_share.name
    }      
  }

  container {
    name   = "prosody"
    image  = "${azurerm_container_registry.acr.login_server}/jitsi/prosody:v1" # NOTE: To be changed according to the private registry images name
    cpu    = "0.5"
    memory = "1.5"
    
    environment_variables = {
      "CONFIG" = "/opt/jitsi-meet-cfg"
      "TZ" = "Europe/Brussels"
      "PUBLIC_URL" = "https://esijitsi${random_id.jitsi_continst_id.hex}.westeurope.azurecontainer.io"
    }
    secure_environment_variables = {
      "JICOFO_AUTH_PASSWORD"="d088c899f0a3c94d78e02a15a8ebea10" # NOTE: Passwords can be changed
      "JVB_AUTH_PASSWORD"="d255b96cc96258aba1b6270710d3eeb7"
      "JIGASI_XMPP_PASSWORD"="665748a740ed9c22ae60d045cea81907"
      "JIBRI_RECORDER_PASSWORD"="ee7cabf04f1b91c0bdf14e6276599d18"
      "JIBRI_XMPP_PASSWORD"="840ada2457c495f58fff8e4ec751be56"
    }
    #commands = [ "value" ]
    ports {
      port     = 5347
      protocol = "TCP"
    }
    ports {
      port     = 5280
      protocol = "TCP"
    }
    volume {
      name                 = "jitsi-config-pro-path"
      mount_path           = "/opt/jitsi-meet-cfg/prosody/prosody-plugins-custom"
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_jitsi_meet_share.name
    }   
    volume {
      name                 = "jitsi-config-pro2-path"
      mount_path           = "/opt/jitsi-meet-cfg/prosody/config"
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_jitsi_meet_share.name
    }        
  }
  container {
    name   = "jicofo"
    image  = "${azurerm_container_registry.acr.login_server}/jitsi/jicofo:v1" # NOTE: To be changed according to the private registry images name
    cpu    = "0.5"
    memory = "1.5"
    
    environment_variables = {
      "CONFIG" = "/opt/jitsi-meet-cfg"
      "TZ" = "Europe/Brussels"
      "JICOFO_AUTH_PASSWORD"="d088c899f0a3c94d78e02a15a8ebea10"
    }
    secure_environment_variables = {
      "JICOFO_AUTH_PASSWORD"="d088c899f0a3c94d78e02a15a8ebea10"
    }
   ports {
      port     = 5222
      protocol = "TCP"
    }
    volume {
      name                 = "jitsi-config-jico-path"
      mount_path           = "/opt/jitsi-meet-cfg/jicofo"
      storage_account_name = azurerm_storage_account.storage_account_cont.name
      storage_account_key  = azurerm_storage_account.storage_account_cont.primary_access_key
      share_name           = azurerm_storage_share.aci_jitsi_meet_share.name
    }      
  }
  container {
    name   = "jvb"
    image  = "${azurerm_container_registry.acr.login_server}/jitsi/jvb:v1" # NOTE: To be changed according to the private registry images name
    cpu    = "0.5"
    memory = "1.5"
    
    environment_variables = {
      "CONFIG" = "/opt/jitsi-meet-cfg"
      "TZ" = "Europe/Brussels"
      "PUBLIC_URL" = "https://esijitsi${random_id.jitsi_continst_id.hex}.westeurope.azurecontainer.io"
    }
    secure_environment_variables = {
      "JVB_AUTH_PASSWORD"="d255b96cc96258aba1b6270710d3eeb7"
    }
    ports {
      port     = 10000
      protocol = "UDP"
    }
    ports {
      port     = 4443
      protocol = "TCP"
    }

}
  diagnostics {
    log_analytics {
      workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.workspace_id
      workspace_key = azurerm_log_analytics_workspace.log_analytics_workspace.primary_shared_key
    }
  } 
}
