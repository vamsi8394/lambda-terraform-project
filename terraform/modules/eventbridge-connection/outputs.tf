output "connection_arn" {
  description = "ARN of the EventBridge connection"
  value       = aws_cloudwatch_event_connection.this.arn
}

output "connection_name" {
  description = "Name of the EventBridge connection"
  value       = aws_cloudwatch_event_connection.this.name
}

output "secret_arn" {
  description = "ARN of the automatically created Secrets Manager secret"
  value       = aws_cloudwatch_event_connection.this.secret_arn
}
