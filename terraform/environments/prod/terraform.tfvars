# AWS Account ID - REPLACE WITH YOUR ACCOUNT ID
aws_account_id = "021891594383"

# Environment
environment = "prod"
aws_region  = "us-east-1"

# Jira Webhook Lambda Configuration
jira_base_url       = "https://pilotflyingj-sandbox-951.atlassian.net"

main_bucket_name = "pfj-legal-tech-contracts-bucket-prod"
log_bucket_name  = "pfj-legal-tech-contracts-logs-prod"
secrets_arn         = "arn:aws:secretsmanager:us-east-1:021891594383:secret:jirawebhookconnections-qazW4L"

# Jira Credentials (Sensitive - should be passed via environment variables or secrets store in CI/CD)
jira_email     = "jira_user_email"
jira_api_token = "jira_api_token"

# Lambda Configuration (Prod environment - production resources)
webhook_lambda_memory        = 1024
webhook_lambda_timeout       = 90
webhook_lambda_log_retention = 30

extracttext_lambda_memory        = 1024
extracttext_lambda_timeout       = 180
extracttext_lambda_log_retention = 30
