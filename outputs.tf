output "key_vault_url" {
  value       = azurerm_key_vault.clinic-keys.vault_uri
  description = "URL of the Key Vault"
}

output "database_id" {
  value       = azurerm_postgresql_flexible_server.clinic-db-server-4Vet.id
  description = "ID of the PostgreSQL server"
  sensitive   = true
}

output "storage_account_name" {
  value       = azurerm_storage_account.blobs.name
  description = "Name of the Blob Storage account"
}

output "storage_container_url" {
  value       = "${azurerm_storage_account.blobs.primary_blob_endpoint}uploads"
  description = "URL of the uploads container"
}

output "webapp_url" {
  value = "https://${azurerm_linux_web_app.app.default_hostname}"
}