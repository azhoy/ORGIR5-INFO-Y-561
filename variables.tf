#####################################################################################################
############################################ @ GENRAL & AD ############################################
#####################################################################################################

variable "location" {
  description = "Location for the resource group and all the resources"
  default     = "West Europe"
  type        = string
}
variable "csv_users_file" {
  description = "Name of the users csv file"
  default = "users.csv"
  type        = string
}

#####################################################################################################
############################################ @ NETWORKING ############################################
#####################################################################################################


variable "services_vnet" {
  description = "Service VNET configuration"
  default = {
    address_space = [ "10.1.0.0/16" ]
    name = "ServicesVNet"
  }
  type = object({
    name                       = string
    address_space              = list(string)

  })
}

#####################################################################################################
############################################ @ MONITORING ############################################
#####################################################################################################


variable "log_analytics_sku" {
  description = "Sku of the log analytics workspace"
  default = "PerGB2018"
  type = string
  
  validation {
    condition = contains(["Free", "Standalone", "PerNode", "PerGB2018"], var.log_analytics_sku)
    error_message = "The log analytics sku is incorrect."
  }
}

variable "log_analytics_retention_days" {
  description = "Workspace data retention in days. Possible values are either 7 (Free Tier only) or range between 30 and 730."
  default = 30
  type        = number
}

variable "log_analytics_solution_plan_map" {
  description = "Solutions to deploy to log analytics workspace"
  default     = {
    ContainerInsights= {
      product   = "OMSGallery/ContainerInsights"
      publisher = "Microsoft"
    }
  }
  type = map(any)
}

variable "action_group_variables" {

  default = {
    action_group_name = "AlertActionGroup"
    action_group_shortname = "aciAction"
    email_address = "tremble_07_ensign@icloud.com"
    email_receiver_name = "sendtodevops"
  }

  type = object({
    action_group_name = string
    action_group_shortname = string
    email_receiver_name         = string
    email_address      = string
  })
}

#####################################################################################################
############################################ @ STORAGE ############################################
#####################################################################################################


variable "storage_account_kind" {
  description = "(Optional) Specifies the account kind of the storage account"
  type        = string
  default = "StorageV2"
   validation {
    condition = contains(["BlockBlobStorage", "BlobStorage", "FileStorage", "Storage", "StorageV2"], var.storage_account_kind)
    error_message = "The account kind of the storage account is invalid."
  }
}

variable "storage_account_tier" {
  description = "(Optional) Specifies the account tier of the storage account"
  type        = string
  default = "Standard"

   validation {
    condition = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "The account tier of the storage account is invalid."
  }
}

variable "storage_account_replication_type" {
  description = "(Optional) Specifies the replication type of the storage account"
  type        = string
  default = "LRS"

  validation {
    condition = contains(["LRS", "ZRS", "GRS", "GZRS", "RA-GRS", "RA-GZRS"], var.storage_account_replication_type)
    error_message = "The replication type of the storage account is invalid."
  }
}


variable "storage_account_default_action" {
    description = "Allow or disallow public access to all blobs or containers in the storage accounts. The default interpretation is true for this property."
    default     = "Allow"
    type        = string  
}

variable "storage_account_ip_rules" {
    description = "Specifies IP rules for the storage account"
    default = [ ]
    type        = list(string)  
}

variable "storage_account_virtual_network_subnet_ids" {
    description = "Specifies a list of resource ids for subnets"
    default = [ ]
    type        = list(string)  
}

#####################################################################################################
############################################ @ Key Vault ############################################
#####################################################################################################

# NOTE: Not used but can be useful for futur implemantation

variable "key_vault_sku_name" {
  description = "(Required) The Name of the SKU used for this Key Vault. Possible values are standard and premium."
  type        = string
  default = "standard"
  validation {
    condition = contains(["standard", "premium" ], var.key_vault_sku_name)
    error_message = "The value of the sku name property of the key vault is invalid."
  }
}

variable "key_vault_enabled_for_deployment" {
  description = "(Optional) Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault. Defaults to false."
  default = true
  type        = bool
}

variable "key_vault_enabled_for_disk_encryption" {
  description = " (Optional) Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. Defaults to false."
  default     = true
  type        = bool
}

variable "key_vault_enabled_for_template_deployment" {
  description = "(Optional) Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault. Defaults to false."
  type        = bool
  default     = false
}

variable "key_vault_enable_rbac_authorization" {
  description = "(Optional) Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions. Defaults to false."
  default = false
  type        = bool
}

variable "key_vault_purge_protection_enabled" {
  description = "(Optional) Is Purge Protection enabled for this Key Vault? Defaults to false."
  default = false
  type        = bool
}

variable "key_vault_soft_delete_retention_days" {
  description = "(Optional) The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days."
  default = 30
  type        = number
}

variable "key_vault_bypass" { 
  description = "(Required) Specifies which traffic can bypass the network rules. Possible values are AzureServices and None."
  type        = string
  default = "AzureServices"

  validation {
    condition = contains(["AzureServices", "None" ], var.key_vault_bypass)
    error_message = "The valut of the bypass property of the key vault is invalid."
  }
}

variable "key_vault_default_action" { 
  description = "(Required) The Default Action to use when no rules match from ip_rules / virtual_network_subnet_ids. Possible values are Allow and Deny."
  type        = string
  default = "Allow"

  validation {
    condition = contains(["Allow", "Deny" ], var.key_vault_default_action)
    error_message = "The value of the default action property of the key vault is invalid."
  }
}

variable "key_vault_ip_rules" { 
  description = "(Optional) One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault."
  default = [ ]
}

variable "key_vault_virtual_network_subnet_ids" { 
  description = "(Optional) One or more Subnet ID's which should be able to access this Key Vault."
  default     = []
}

#####################################################################################################
############################################ @ Container ############################################
#####################################################################################################

variable "caddy_variables" {
default = {
  container_name = "all/caddy"
  image_version = "v1"
}
  type = object({
    container_name  = string
    image_version = string
  })
}

# % Mattermost
variable "mattermost_variables" {

  default = {
    container_name = "mattermost/mattermost-entreprise-edition"
    image_version = "v1"
    MATTERMOST_CONFIG_PATH         = "/volumes/app/mattermost/config"
    MATTERMOST_DATA_PATH           = "/volumes/app/mattermost/data"
    MATTERMOST_LOGS_PATH           = "/volumes/app/mattermost/logs"
    MATTERMOST_PLUGINS_PATH        = "/volumes/app/mattermost/plugins"
    MATTERMOST_CLIENT_PLUGINS_PATH = "/volumes/app/mattermost/client/plugins"
    MATTERMOST_BLEVE_INDEXES_PATH  = "/volumes/app/mattermost/bleve-indexes"
    MM_BLEVESETTINGS_INDEXDIR      = "/mattermost/bleve-indexes"
    TZ                             = "Europe/Brussels"
    port                           = 8065
    protocol                       = "TCP"
  }

  type = object({
    container_name                 = string
    image_version                  = string
    MATTERMOST_CONFIG_PATH         = string
    MATTERMOST_DATA_PATH           = string
    MATTERMOST_LOGS_PATH           = string
    MATTERMOST_PLUGINS_PATH        = string
    MATTERMOST_CLIENT_PLUGINS_PATH = string
    MATTERMOST_BLEVE_INDEXES_PATH  = string
    MM_BLEVESETTINGS_INDEXDIR      = string
    TZ                             = string
    port                           = number
    protocol                       = string
  })
}
variable "mattermost_postgres_variables" {

  default = {
    container_name = "all/postgres"
    image_version = "v1"
    POSTGRES_DB = "mattermost"
    POSTGRES_PASSWORD = "zmxwzb96kXINenCs"
    POSTGRES_USER = "esistudent"
    POSTGRES_DATA_PATH = "/postgresql/data"
    TZ = "Europe/Brussels"
    port = 5432
    protocol = "TCP"
  }

  type = object({
    container_name     = string
    image_version      = string
    TZ                 = string
    POSTGRES_USER      = string
    POSTGRES_PASSWORD  = string
    POSTGRES_DB        = string
    POSTGRES_DATA_PATH = string
    port               = number
    protocol           = string
  })
}
# % Nextcloud
variable "nextcloud_postgres_variables" {

  default = {
    container_name = "all/postgres"
    image_version = "v1"
    POSTGRES_DB = "nextcloud"
    POSTGRES_PASSWORD = "57c495f58ff57c"
    POSTGRES_USER = "esistudent"
    POSTGRES_DATA_PATH = "/postgresql/data"
    TZ = "Europe/Brussels"
    port = 5432
    protocol = "TCP"
  }

  type = object({
    container_name     = string
    image_version      = string
    TZ                 = string
    POSTGRES_USER      = string
    POSTGRES_PASSWORD  = string
    POSTGRES_DB        = string
    POSTGRES_DATA_PATH = string
    port               = number
    protocol           = string
  })
}

variable "nextcloud_variables" {

  default = {
    container_name = "nextcloud/nextcloud"
    image_version = "v1"
    POSTGRES_HOST = "db"
    REDIS_HOST = "redis"
    TZ    = "Europe/Brussels"
    port   = 8080
    protocol = "TCP"
  }

  type = object({
    container_name                 = string
    image_version                  = string
    POSTGRES_HOST = string
    REDIS_HOST = string
    port                           = number
    protocol                       = string
  })
}

# % Invoice Ninja
# NOTE: No time to implement
variable "invoice_variables" {
  default = {
    APP_CIPHER = "AES-256-CBC"
    APP_DEBUG = true
    APP_ENV = "production"
    APP_KEY = "base64:Mz5BYHy6y8on0HQzMYo2Le214jwNnaNSRNrjAigchgA="
    #DB_DATABASE = "ninja"
    DB_HOST = "localhost"
    #DB_PASSWORD = "0Z8kUsqCqQlJaAnI"
    DB_STRICT = "false"
    DB_TYPE = "mysql"
    #DB_USERNAME = "esistudent"
    REMEMBER_ME_ENABLED = false
    REQUIRE_HTTPS = true
    container_name = "invoiceninja/invoiceninja"
    image_version = "v1"
    port = 8080
    protocol = "TCP"
    NINJA_PUBLIC_PATH  = "/var/invoiceninja/public"
    NINJA_STORAGE_PATH = "/var/invoiceninja/storage"
  }

  type = object({
    container_name       = string
    image_version        = string
    APP_CIPHER = string
    APP_DEBUG = bool
    APP_ENV = string
    APP_KEY = string
    DB_HOST = string
    DB_STRICT = string
    DB_TYPE = string
    REMEMBER_ME_ENABLED = bool
    REQUIRE_HTTPS = bool
    port                 = number
    protocol             = string
    NINJA_PUBLIC_PATH    = string
    NINJA_STORAGE_PATH   = string
  })
}

# NOTE: No time to implement
variable "invoice_mysql_variables" {
     default = {
       MYSQL_DATABASE = "ninja"
       MYSQL_PASSWORD = "0Z8kUsqCqQlJaAnI"
       MYSQL_ROOT_PASSWORD = "0Z8kUsqCqQlJaAnI"
       MYSQL_USER = "ninja"
       MYSQL_DATA_PATH = "/mysql/data"
       container_name = "all/mysql"
       image_version = "v1"
       port = 3306
       protocol = "TCP"
     }

  type = object({
    container_name      = string
    image_version       = string
    MYSQL_ROOT_PASSWORD = string
    MYSQL_DATABASE      = string
    MYSQL_USER          = string
    MYSQL_PASSWORD      = string
    MYSQL_DATA_PATH     = string
    port                = number
    protocol            = string
  })
}

# NOTE: No time to implement
variable "bitwarden_variables" {

  default = {
    KEYCLOAK_PASSWORD = "5XD2zLwqaWXqPI7u"
    KEYCLOAK_USER = "esistudent"
    DB_VENDOR    = "postgres"
    DB_ADDR  = "localhost"
    container_name = "keycloak/keycloak"
    image_version = "v1"
    port = 8080
    protocol = "TCP"
  }

  type = object({
    container_name        = string
    image_version         = string
    KEYCLOAK_USER         = string
    KEYCLOAK_PASSWORD     = string
    DB_VENDOR             = string
    DB_ADDR               = string
    port                  = number
    protocol              = string
  })
}
