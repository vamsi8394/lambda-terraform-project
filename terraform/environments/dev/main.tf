locals {
  lambda_source_dir = "${path.module}/../../../lambdas"
}

# S3 Bucket Module
module "s3" {
  source = "../../modules/s3"

  main_bucket_name = var.main_bucket_name
  log_bucket_name  = var.log_bucket_name
  log_prefix       = var.log_prefix

  tags = {
    Environment = var.environment
  }
}

# Jira Webhook Lambda
module "jira_webhook_lambda" {
  source = "../../modules/lambda"

  function_name           = "tech-jirawebhooklambda-${var.environment}"
  description             = "Processes Jira webhook events for contract attachments"
  runtime                 = "python3.13"
  architecture            = "arm64"
  memory_size             = var.webhook_lambda_memory
  ephemeral_storage_size  = 512
  timeout                 = var.webhook_lambda_timeout
  source_dir              = "${local.lambda_source_dir}/tech-jirawebhooklambda"
  handler                 = "lambda_function.lambda_handler"
  log_retention_days      = var.webhook_lambda_log_retention

  environment_variables = {
    JIRA_BASE_URL       = var.jira_base_url
    JIRA_CONNECTION_ARN = module.jira_connection.connection_arn
    STATE_MACHINE_ARN   = module.contract_analysis_workflow.state_machine_arn
    S3_BUCKET_NAME      = module.s3.main_bucket_name
    SECRETS_ARN         = var.secrets_arn
  }

  iam_policy_statements = [
    {
      sid    = "AllowS3Upload"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      resources = [
        "${module.s3.main_bucket_arn}/contracts/*"
      ]
    },
    {
      sid    = "AllowSecretsManagerRead"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = [
        var.secrets_arn
      ]
    },
    {
      sid    = "AllowSFNStartExecution"
      effect = "Allow"
      actions = [
        "states:StartExecution"
      ]
      resources = [
        module.contract_analysis_workflow.state_machine_arn
      ]
    }
  ]

  tags = {
    Name        = "tech-jirawebhooklambda-${var.environment}"
    Environment = var.environment
    Function    = "JiraWebhookProcessor"
  }
}

# WAF for API Gateway
module "waf" {
  source = "../../modules/waf"

  name  = "tech-JiraWebhookWAF-${var.environment}"
  scope = "REGIONAL"

  tags = {
    Name        = "tech-JiraWebhookWAF-${var.environment}"
    Environment = var.environment
  }
}

# API Gateway for Jira Webhook
module "webhook_api_gateway" {
  source = "../../modules/api-gateway"

  api_name               = "tech-JiraWebhookAPI-${var.environment}"
  api_description        = "API Gateway for Jira webhook events"
  stage_name             = var.environment
  lambda_invoke_arn      = module.jira_webhook_lambda.invoke_arn
  lambda_function_name   = module.jira_webhook_lambda.function_name
  resource_path          = "webhook"
  http_method            = "POST"
  binary_media_types     = ["*/*"]
  throttling_rate_limit  = 1000
  throttling_burst_limit = 500
  waf_web_acl_arn        = module.waf.web_acl_arn
  enable_cors            = true

  tags = {
    Name        = "tech-JiraWebhookAPI-${var.environment}"
    Environment = var.environment
  }
}

# Extract Text Lambda
module "extract_text_lambda" {
  source = "../../modules/lambda"

  function_name           = "tech-extracttextlambda-${var.environment}"
  description             = "Extracts text from PDF/DOCX and performs contract analysis using Bedrock"
  runtime                 = "python3.13"
  architecture            = "arm64"
  memory_size             = var.extracttext_lambda_memory
  ephemeral_storage_size  = 512
  timeout                 = var.extracttext_lambda_timeout
  source_dir              = "${local.lambda_source_dir}/tech-extracttextlambda"
  handler                 = "lambda_function.lambda_handler"
  log_retention_days      = var.extracttext_lambda_log_retention

  environment_variables = {
    S3_BUCKET_NAME = module.s3.main_bucket_name
    AWS_REGION     = var.aws_region
  }

  iam_policy_statements = [
    {
      sid    = "AllowS3Read"
      effect = "Allow"
      actions = [
        "s3:GetObject"
      ]
      resources = [
        "${module.s3.main_bucket_arn}/*"
      ]
    },
    {
      sid    = "AllowBedrockAccess"
      effect = "Allow"
      actions = [
        "bedrock:*"
      ]
      resources = [
        "*"
      ]
    }
  ]

  tags = {
    Name        = "tech-extracttextlambda-${var.environment}"
    Environment = var.environment
    Function    = "ContractTextExtraction"
  }
}

# EventBridge Connection for Jira
module "jira_connection" {
  source = "../../modules/eventbridge-connection"

  connection_name = "Jira-Connection-${var.environment}"
  description     = "Connection to Jira for contract analysis workflow"
  jira_email      = var.jira_email
  jira_api_token  = var.jira_api_token

  tags = {
    Name        = "Jira-Connection-${var.environment}"
    Environment = var.environment
  }
}

# Step Functions Workflow
module "contract_analysis_workflow" {
  source = "../../modules/step-functions"

  state_machine_name = "TechContractAnalysisWorkflow-${var.environment}"
  definition = templatefile("${path.module}/../../templates/state_machine.asl.json", {
    extract_text_lambda_arn = module.extract_text_lambda.function_arn
  })

  create_role = true
  lambda_function_arns = [module.extract_text_lambda.function_arn]
  eventbridge_connection_arns = [module.jira_connection.connection_arn]
  
  # IAM Policy Variables
  s3_bucket_name = module.s3.main_bucket_name
  jira_base_url  = var.jira_base_url

  tags = {
    Name        = "TechContractAnalysisWorkflow-${var.environment}"
    Environment = var.environment
  }
}
