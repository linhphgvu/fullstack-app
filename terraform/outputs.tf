output "frontend_url" {
  value = google_cloud_run_service.frontend.status[0].url
  description = "frontend URL"
}
output "backend_url" {
  value = google_cloud_run_service.backend.status[0].url
   description = "backend URL"
}

output "database_connection_name" {
  description = "Database connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository for Docker images"
  value       = google_artifact_registry_repository.main.repository_id
}

output "project_number" {
  description = "Project number for Cloud Build service account"
  value       = data.google_project.project.number
}