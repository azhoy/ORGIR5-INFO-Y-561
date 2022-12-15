
# When imorting
#resource "azurerm_container_registry" "acr" {}

# Once imported
resource "azurerm_container_registry" "acr" {
    location                      = "westeurope"
    name                          = "<acrName>"
    resource_group_name           = "<resourceGroupName>"
    sku                           = "Basic"
    admin_enabled                 = true
}
