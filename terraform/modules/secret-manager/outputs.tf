output "secret_arn" {
  description = "ARN of the secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_id" {
  description = "ID of the secret"
  value       = aws_secretsmanager_secret.this.id
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.this.name
}

output "version_id" {
  description = "Version ID of the secret version"
  value       = aws_secretsmanager_secret_version.this.version_id
}
