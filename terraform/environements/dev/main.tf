# Local variables
locals {
  lambda_source_dir = "${path.module}/../../../lambda"
}

# S3 module for storing contracts and logs
module "s3" {
  source = "../../modules/S3"

  main_bucket_name = var.main_bucket_name
  log_bucket_name  = var.log_bucket_name
  log_prefix       = var.log_prefix

  tags = {
    Environment = var.environment
  }
}

# Secrets Manager for Jira credentials
module "jira_secrets" {
  source = "../../modules/secret-manager"

  secret_name = "jira-credentials-${var.environment}"
  description = "Jira API credentials for webhook authentication"

  secret_value = jsonencode({
    email     = var.jira_email
    api_token = var.jira_api_token
  })

  tags = {
    Name        = "jira-credentials-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# EventBridge Connection for Jira API authentication (used by Step Functions)
module "jira_eventbridge_connection" {
  source = "../../modules/eventbridge-connection"

  connection_name = "jira-connection-${var.environment}"
  description     = "EventBridge connection for Jira API authentication - ${var.environment}"
  username        = var.jira_email
  password        = var.jira_api_token

  tags = {
    Name        = "jira-connection-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# WAF module to protect the API Gateway
module "waf" {
  source = "../../modules/waf"

  name  = "tech-JiraWebhookWAF-${var.environment}"
  scope = "REGIONAL"

  tags = {
    Name        = "tech-JiraWebhookWAF-${var.environment}"
    Environment = var.environment
  }
}

# Lambda Layer for required Python dependencies (PyPDF2, docx2txt, etc.)
module "extract_text_layer" {
  source = "../../modules/lambda-layer"

  layer_name               = "tech-extracttext-dependencies-${var.environment}"
  description              = "Python dependencies for text extraction (PyPDF2, docx2txt, boto3)"
  compatible_runtimes      = ["python3.13", "python3.12", "python3.11", "python3.10", "python3.9"]
  compatible_architectures = ["arm64"]
  layer_zip_path           = "${path.module}/../../../layers/python-dependencies.zip"
}

# Lambda function for text extraction and Bedrock analysis (part of the Step Function workflow)
module "extract_text_lambda" {
  source = "../../modules/lambda"

  function_name          = "tech-extracttextlambda-${var.environment}"
  description            = "Extracts text from PDF/DOCX and performs contract analysis using Bedrock"
  runtime                = "python3.13"
  architecture           = "arm64"
  memory_size            = var.extracttext_lambda_memory
  ephemeral_storage_size = 512
  timeout                = var.extracttext_lambda_timeout
  source_dir             = "${local.lambda_source_dir}/tech-extracttextlambda"
  handler                = "lambda_function.lambda_handler"
  log_retention_days     = var.extracttext_lambda_log_retention

  layers = [module.extract_text_layer.layer_arn]

  environment_variables = {
    S3_BUCKET_NAME                = module.s3.main_bucket_name
    BEDROCK_LITE_MODEL            = "amazon.nova-lite-v1:0"
    BEDROCK_PRO_MODEL             = "amazon.nova-pro-v1:0"
    MAX_CHARS_FOR_CLASSIFICATION  = "20000"
    MAX_CHARS_FOR_ANALYSIS        = "260000"
    MAX_OUTPUT_TOKENS             = "15000"
    PDF_MAX_FAILURE_RATE          = "0.5"
    PDF_MIN_PAGES_BEFORE_FAILFAST = "5"
  }

  iam_policy_statements = [
    {
      # Allows reading the contract file from S3
      sid       = "AllowS3Read"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.s3.main_bucket_arn}/*"]
    },
    {
      # Allows interacting with the Bedrock foundation models
      sid     = "AllowBedrockInvokeModels"
      effect  = "Allow"
      actions = ["bedrock:InvokeModel"]
      resources = [
        "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.nova-lite-v1:0",
        "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.nova-pro-v1:0"
      ]
    }
  ]

  tags = {
    Name        = "tech-extracttextlambda-${var.environment}"
    Environment = var.environment
    Function    = "ContractTextExtraction"
  }
}

# Step Functions State Machine for contract analysis workflow
module "contract_analysis_workflow" {
  source = "../../modules/stepfunction"

  state_machine_name = "tech-ContractAnalysisWorkflow-${var.environment}"
  description        = "Orchestrates contract analysis workflow"

  definition = templatefile("${path.module}/state-machine-definition.json", {
    extract_text_lambda_arn = module.extract_text_lambda.arn
    jira_connection_arn     = module.jira_eventbridge_connection.connection_arn
  })

  iam_policy_statements = [
    {
      sid       = "AllowLambdaInvoke"
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = [module.extract_text_lambda.arn]
    },
    {
      sid       = "AllowEventBridgeConnection"
      effect    = "Allow"
      actions   = ["events:RetrieveConnectionCredentials"]
      resources = [module.jira_eventbridge_connection.connection_arn]
    },
    {
      sid       = "AllowSecretsManagerInvoke"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.jira_eventbridge_connection.secret_arn]
    }
  ]

  tags = {
    Name        = "tech-ContractAnalysisWorkflow-${var.environment}"
    Environment = var.environment
  }

  depends_on = [module.extract_text_lambda, module.jira_eventbridge_connection]
}

# Lambda function for handling incoming Jira webhooks
module "jira_webhook_lambda" {
  source = "../../modules/lambda"

  function_name          = "tech-jirawebhooklambda-${var.environment}"
  description            = "Processes Jira webhook events for contract attachments"
  runtime                = "python3.13"
  architecture           = "arm64"
  memory_size            = var.webhook_lambda_memory
  ephemeral_storage_size = 512
  timeout                = var.webhook_lambda_timeout
  source_dir             = "${local.lambda_source_dir}/tech-jirawebhooklambda"
  handler                = "lambda_function.lambda_handler"
  log_retention_days     = var.webhook_lambda_log_retention

  environment_variables = {
    JIRA_BASE_URL       = var.jira_base_url
    JIRA_CONNECTION_ARN = module.jira_eventbridge_connection.connection_arn
    STATE_MACHINE_ARN   = module.contract_analysis_workflow.state_machine_arn
    S3_BUCKET_NAME      = module.s3.main_bucket_name
    SECRETS_ARN         = module.jira_secrets.secret_arn
  }

  iam_policy_statements = [
    {
      # Allows uploading the document from Jira to S3
      sid       = "AllowS3Upload"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${module.s3.main_bucket_arn}/contracts/*"]
    },
    {
      # Allows reading Jira credentials from Secrets Manager
      sid       = "AllowSecretsManagerRead"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.jira_secrets.secret_arn]
    },
    {
      # Allows starting the contract analysis workflow
      sid       = "AllowSFNStartExecution"
      effect    = "Allow"
      actions   = ["states:StartExecution"]
      resources = [module.contract_analysis_workflow.state_machine_arn]
    },
    {
      # Standard CloudWatch Logs permissions
      sid       = "AllowCloudWatchLogs"
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/tech-jirawebhooklambda-${var.environment}:*"]
    }
  ]

  tags = {
    Name        = "tech-jirawebhooklambda-${var.environment}"
    Environment = var.environment
    Function    = "JiraWebhookProcessor"
  }
}

# API Gateway to expose the Lambda function publicly for the Jira webhook
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
  enable_waf_association = true
  enable_cors            = true

  tags = {
    Name        = "tech-JiraWebhookAPI-${var.environment}"
    Environment = var.environment
  }

  depends_on = [module.waf]
}
