# Development environment configuration
project_id  = "central-kit-466202-p7"
app_name    = "fullstack-app"
environment = "staging"
region      = "asia-southeast1"

# Development-specific settings
db_tier = "db-f1-micro"
min_instances = 1
max_instances = 10

# Custom domain for staging
domain = "staging.myapp.com"
backup_retention_days = 14