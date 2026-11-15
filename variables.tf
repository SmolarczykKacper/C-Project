# variable "secret_key" {
#   type        = string
#   sensitive   = true
#   description = "Secret key for API (will be stored in KV)"
# }

# variable "db_password" {
#   type        = string
#   sensitive   = true
#   description = "Database password (will be stored in KV)"
# }

variable "host" {
  type        = string
  description = "Database host"
  default     = "clinic-db-server.postgres.database.azure.com"
}

variable "username" {
  type        = string
  description = "Database administrator username"
  default     = "clinicadmin"
}

variable "database" {
  type        = string
  description = "Database name"
  default     = "main-db"
}