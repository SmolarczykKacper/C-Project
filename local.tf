locals {
  kv = azurerm_key_vault.clinic-keys.vault_uri

  secrets = {
    db_password   = "db-password"
    secret_key    = "secret-key"
  }

  kv_refs = {
    for k, v in local.secrets :
    k => "@Microsoft.KeyVault(SecretUri=${local.kv}secrets/${v})"
  }
}
