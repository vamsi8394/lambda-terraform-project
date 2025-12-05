# Environment configuration
environment    = "dev"
aws_region     = "us-east-1"
aws_account_id = "861276084741"

# S3 bucket names (must be globally unique)
main_bucket_name = "tech-jira-contracts-dev"
log_bucket_name  = "tech-jira-logs-dev"
log_prefix       = "access-logs/"

# Jira configuration
jira_base_url = "https://yourcompany.atlassian.net"
# NOTE: Sensitive values should be set via environment variables or AWS Secrets Manager
# jira_email     = "your-email@company.com"
# jira_api_token = "your-api-token"

# Lambda configuration - Webhook Lambda
webhook_lambda_memory        = 512
webhook_lambda_timeout       = 30
webhook_lambda_log_retention = 7

# Lambda configuration - Extract Text Lambda  
extracttext_lambda_memory        = 2048
extracttext_lambda_timeout       = 300
extracttext_lambda_log_retention = 7
