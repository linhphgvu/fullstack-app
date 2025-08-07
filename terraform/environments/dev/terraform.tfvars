# Development environment configuration
project_id  = "central-kit-466202-p7"
app_name    = "fullstack-app"
environment = "dev"
region      = "asia-southeast1"

# Development-specific settings
db_tier = "db-f1-micro"
min_instances = 0
max_instances = 5

# Cost optimization for dev
enable_debug_logging = true
backup_retention_days = 7