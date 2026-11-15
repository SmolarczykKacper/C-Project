resource "azurerm_resource_group" "main" {
  name     = "main"
  location = "italynorth"

  tags = {
    environment = "production"
    project     = "4-Vet"
  }
}

data "azurerm_client_config" "current" {}
resource "random_string" "db_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_user_assigned_identity" "webapp_identity" {
  name                = "clinic-webapp-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_key_vault_access_policy" "webapp" {
  key_vault_id = azurerm_key_vault.clinic-keys.id

  tenant_id = azurerm_user_assigned_identity.webapp_identity.tenant_id
  object_id = azurerm_user_assigned_identity.webapp_identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_key_vault" "clinic-keys" {
  name                        = "clinic-keys-${random_string.db_suffix.result}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7

  sku_name = "standard"
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
    ]

    secret_permissions = [
        "Get",
        "Set",
        "Delete",
        "Purge",
        "Recover",
        "List"
    ]

    storage_permissions = [
      "Set",
      "Get",
      "List",
    ]
  }

  tags = {
    environment = "production"
    project     = "4-Vet"
  }
}

data "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  key_vault_id = azurerm_key_vault.clinic-keys.id
}

# resource "azurerm_key_vault_secret" "secret-key" {
#   name         = "secret-key"
#   value        = var.secret_key
#   key_vault_id = azurerm_key_vault.clinic-keys.id
# }

# resource "azurerm_key_vault_secret" "db-password" {
#   name         = "db-password"
#   value        = var.db_password
#   key_vault_id = azurerm_key_vault.clinic-keys.id
# }

resource "azurerm_storage_account" "blobs" {
  name                     = "clinicblobs"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
  account_kind            = "StorageV2"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    environment = "production"
    project     = "4-Vet"
  }
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name   = azurerm_storage_account.blobs.name
  container_access_type = "private"
}
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name   = azurerm_storage_account.blobs.name
  container_access_type = "private"
}
resource "azurerm_service_plan" "plan" {
  name                = "clinic-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app" {
  name                = "clinic-api-4Vet"
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.plan.id
  location            = azurerm_service_plan.plan.location

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }


    health_check_path = "/api"
    health_check_eviction_time_in_min  = 5
  }

  app_settings = {
    "ENV" = "production"
    "Database__Host" = azurerm_postgresql_flexible_server.clinic-db-server-4Vet.fqdn
    "Database__Username" = var.username
    "Database__Password" = "NkZ341!klMn8@4!?"
    "Database__Name" = azurerm_postgresql_flexible_server_database.main-db.name
    "Api__Key" = "51d4!2$^hav6hdchyj534@@351shSGNZ"
    "Api__ValidIssuer" = "backend"
    "Api__ValidAudience" = "api"
    "AzureStorage__AccountName" = azurerm_storage_account.blobs.name
    "AzureStorage__ConnectionString" = azurerm_storage_account.blobs.primary_connection_string
    "AzureStorage__ContainerName" = "uploads"
    "Database__SSLMode" = "Require"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.webapp_identity.id
   ]
  
   }
     depends_on = [
        azurerm_key_vault_access_policy.webapp
    ]
  key_vault_reference_identity_id = azurerm_user_assigned_identity.webapp_identity.id

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].dotnet_version
    ]
  }
}

resource "azurerm_application_insights" "app" {
  name                = "clinic-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id  # opcjonalnie, ale zalecane
  retention_in_days   = 90

  tags = {
    environment = "production"
    project     = "4-Vet"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "clinic-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = "production"
    project     = "4-Vet"
  }
}

resource "azurerm_postgresql_flexible_server" "clinic-db-server-4Vet" {
  name                          = "clinic-db-${random_string.db_suffix.result}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  public_network_access_enabled = true
  version                       = "16"
  zone                          = "2"
  administrator_login           = var.username
  administrator_password        = data.azurerm_key_vault_secret.db_password.value

  sku_name  = "B_Standard_B1ms"
  storage_mb = 32768

  tags = {
    environment = "production"
    project     = "4-Vet"
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.clinic-db-server-4Vet.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_postgresql_flexible_server_database" "main-db" {
  name      = "main-db"
  server_id = azurerm_postgresql_flexible_server.clinic-db-server-4Vet.id
  collation = "en_US.utf8"
  charset   = "UTF8"
  lifecycle {
    prevent_destroy = false
  }
}