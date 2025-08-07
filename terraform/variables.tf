variable "project_id" {
  description = "GCP project ID"
  type = string
}

variable "region" {
  description = "GCP project region"
  type = string
  default = "us-central1"
}

variable "app_name" {
  description = "Project app name"
  type = string
  default = "fullstack-app"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type = string
  default = "dev"
}

variable "domain" {
  description = "Project app domain"
  type = string
  default = ""
}

variable "db_tier" {
  description = "Database instance tier"
  type = string
  default = "db-f1-micro"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 100
}

variable "backup_retention_days" {
  description = "Database backup retention in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "enable_debug_logging" {
  description = "Enable debug logging"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable advanced monitoring"
  type        = bool
  default     = false
}