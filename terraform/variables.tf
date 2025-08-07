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