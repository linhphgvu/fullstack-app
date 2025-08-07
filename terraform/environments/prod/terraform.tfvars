project_id  = "central-kit-466202-p7"
app_name    = "fullstack-app"
environment = "staging"
region      = "asia-southeast1"

# Production-specific settings
db_tier = "db-custom-4-8192"
min_instances = 2
max_instances = 100

# Production domain
domain = "myapp.com"

# Enable production features
backup_retention_days = 30
deletion_protection = true
enable_monitoring = true