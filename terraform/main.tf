terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
  
  backend "gcs" {
    bucket = "central-kit-466202-p7-terraform-state"  
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  name_prefix = "${lower(var.app_name)}-${lower(var.environment)}"
}

resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  
  service            = each.value
  disable_on_destroy = false
}


resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "${local.name_prefix}-repo"
  description   = "Docker repository for ${var.app_name}"
  format        = "DOCKER"
  
  depends_on = [google_project_service.services]
}

resource "google_compute_network" "main" {
  name = "${local.name_prefix}-vpc-netw"
  auto_create_subnetworks = true
}

resource "google_compute_subnetwork" "main" {
  name = "${local.name_prefix}-subnetw"
  ip_cidr_range = "10.0.0.0/24"  
  network = google_compute_network.main.id
  region = var.region
  
}

resource "random_id" "suffix" {
  byte_length = 2  
}

#cloud run vpc connector
resource "google_vpc_access_connector" "main" {
  name          = "${substr(local.name_prefix, 0, 8)}-cn-${random_id.suffix.hex}"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.main.name
  region        = var.region
  min_throughput  = 200
  max_throughput  = 300
  depends_on = [google_project_service.services]
}

#db password 
resource "random_password" "db_password" {
  length  = 16
  special = true
}

#private connection 

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_global_address" "private_ip_range" {
  name          = "${local.name_prefix}-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

#cloudsql for postgresql db 
resource "google_sql_database_instance" "main" {
  name             = "${local.name_prefix}-db"
  database_version = "POSTGRES_15"
  region = var.region
  settings {
    tier = var.db_tier
    backup_configuration {
      enabled = true
      start_time = "3:00" 
    }
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.main.id
    }
    database_flags {
      name = "log_statement"
      value = "all"
    }
    deletion_protection_enabled = false #set this to true in prod env 
  }
  depends_on = [google_project_service.services,  
                google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "app_db" {
  name     = var.app_name
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app_user" {
  name     = "${var.app_name}_user"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

#cloud run service for backend api
resource "google_cloud_run_service" "backend" {
  name     = "${local.name_prefix}-backend"
  location = var.region
  depends_on = [google_project_service.services]
  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "5"
        "run.googleapis.com/cloudsql-instances" = "${var.project_id}:${var.region}:${google_sql_database_instance.main.name}"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.main.name
      }
    }
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}/backend:latest"
        ports {
          container_port = 8080
        }
        env {
          name = "NODE_ENV"
          value = var.environment
        }
        env {
          name = "DATABASE_URL"
          value = "postgresql://${google_sql_user.app_user.name}:${google_sql_user.app_user.password}@${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.app_db.name}"
        }
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

#cloud run service for frontend 
resource "google_cloud_run_service" "frontend" {
  name     = "${local.name_prefix}-frontend"
  location = var.region

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "5"
      }
    }

    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}/frontend:latest"
        
        ports {
          container_port = 80
        }

        env {
          name  = "REACT_APP_API_URL"
          value = google_cloud_run_service.backend.status[0].url
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "256Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.services]
}

#iam binding for public access
resource "google_cloud_run_service_iam_member" "backend" {
  service = google_cloud_run_service.backend.name
  location = google_cloud_run_service.backend.location
  role = "roles/run.invoker"
  member = "allUsers"
}

resource "google_cloud_run_service_iam_member" "frontend" {
  service = google_cloud_run_service.frontend.name
  location = google_cloud_run_service.frontend.location
  role = "roles/run.invoker"
  member = "allUsers"
}
#cloud build service account permission 
resource "google_project_iam_member" "cloudbuild_run_admin" {
  project = var.project_id
  role = "roles/run.admin"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}
resource "google_project_iam_member" "cloudbuild_artifact_registry" {
  project = var.project_id
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}
resource "google_project_iam_member" "cloudbuild_iam_admin" {
  project = var.project_id
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

#get project information
data "google_project" "project" {
}
 
