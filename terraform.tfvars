location = "West Europe"
csv_users_file = "users.csv"

services_vnet = {
  name = "ServicesVNet"
  address_space = [
    "10.1.0.0/16"
  ]
}

log_analytics_sku = "PerGB2018"
log_analytics_retention_days = 30
  log_analytics_solution_plan_map     = {
    ContainerInsights= {
      product   = "OMSGallery/ContainerInsights"
      publisher = "Microsoft"
    }
  }
action_group_variables = {
    action_group_name = "AlertActionGroup"
    action_group_shortname = "aciAction"
    email_address = "<adminEmail>"
    email_receiver_name = "admin"
  }
  
storage_account_kind = "StorageV2"
storage_account_tier = "Standard"
storage_account_replication_type = "LRS"
storage_account_default_action = "Allow"

# NOTE: Not used but can be useful for futur implemantation
key_vault_sku_name = "standard"
key_vault_enabled_for_deployment = true
key_vault_enabled_for_disk_encryption = true
key_vault_enabled_for_template_deployment = false
key_vault_enable_rbac_authorization = false
key_vault_purge_protection_enabled = false
key_vault_soft_delete_retention_days = 30
key_vault_bypass = "AzureServices"
key_vault_default_action = "Allow"
key_vault_ip_rules = [ ]
key_vault_virtual_network_subnet_ids = [ ]

caddy_variables = {
  container_name = "all/caddy"
  image_version = "v1"
}

mattermost_variables = {
    container_name = "mattermost/mattermost-entreprise-edition"
    image_version = "v1"
    MATTERMOST_CONFIG_PATH         = "/volumes/app/mattermost/config"
    MATTERMOST_DATA_PATH           = "/volumes/app/mattermost/data"
    MATTERMOST_LOGS_PATH           = "/volumes/app/mattermost/logs"
    MATTERMOST_PLUGINS_PATH        = "/volumes/app/mattermost/plugins"
    MATTERMOST_CLIENT_PLUGINS_PATH = "/volumes/app/mattermost/client/plugins"
    MATTERMOST_BLEVE_INDEXES_PATH  = "/volumes/app/mattermost/bleve-indexes"
    MM_BLEVESETTINGS_INDEXDIR      = "/mattermost/bleve-indexes"
    TZ = "Europe/Brussels"
    port = 8065
    protocol = "TCP"
}

mattermost_postgres_variables = {
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

nextcloud_postgres_variables = {
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

nextcloud_variables = {
    container_name = "nextcloud/nextcloud"
    image_version = "v1"
    POSTGRES_HOST = "db"
    REDIS_HOST = "redis"
    TZ    = "Europe/Brussels"
    port   = 8080
    protocol = "TCP"
}

invoice_variables = {
  APP_CIPHER = "AES-256-CBC"
  APP_DEBUG = true 
  APP_ENV = "production"
  APP_KEY = "base64:Mz5BYHy6y8on0HQzMYo2Le214jwNnaNSRNrjAigchgA="
  #DB_DATABASE = "ninja"
  DB_HOST = "localhost"
  DB_PASSWORD = "0Z8kUsqCqQlJaAnI"
  DB_STRICT = "false"
  DB_TYPE = "mysql"
  #DB_USERNAME = "ninja"
  REMEMBER_ME_ENABLED = false
  REQUIRE_HTTPS = true
  container_name = "invoiceninja/invoiceninja"
  image_version = "v1"
  port = 8080
  protocol = "TCP"
  NINJA_PUBLIC_PATH  = "/var/invoiceninja/public"
  NINJA_STORAGE_PATH = "/var/invoiceninja/storage"

}

invoice_mysql_variables = {
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
