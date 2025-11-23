output "jira_webhook_lambda_arn" {
  description = "ARN of the Jira webhook Lambda function"
  value       = module.jira_webhook_lambda.function_arn
}

output "jira_webhook_lambda_name" {
  description = "Name of the Jira webhook Lambda function"
  value       = module.jira_webhook_lambda.function_name
}

output "webhook_api_endpoint" {
  description = "API Gateway endpoint URL for webhook"
  value       = module.webhook_api_gateway.api_endpoint
}

output "webhook_api_id" {
  description = "API Gateway ID"
  value       = module.webhook_api_gateway.api_id
}

output "webhook_api_execution_arn" {
  description = "API Gateway execution ARN"
  value       = module.webhook_api_gateway.execution_arn
}

output "extract_text_lambda_arn" {
  description = "ARN of the extract text Lambda function"
  value       = module.extract_text_lambda.function_arn
}

output "extract_text_lambda_name" {
  description = "Name of the extract text Lambda function"
  value       = module.extract_text_lambda.function_name
}

output "jira_connection_arn" {
  description = "ARN of the EventBridge connection"
  value       = module.jira_connection.connection_arn
}

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.contract_analysis_workflow.state_machine_arn
}

output "main_bucket_name" {
  description = "Name of the main S3 bucket"
  value       = module.s3.main_bucket_name
}

output "log_bucket_name" {
  description = "Name of the log S3 bucket"
  value       = module.s3.log_bucket_name
}
