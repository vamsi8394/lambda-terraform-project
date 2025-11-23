output "main_bucket_id" {
  description = "The ID of the main S3 bucket"
  value       = aws_s3_bucket.main_bucket.id
}

output "main_bucket_arn" {
  description = "The ARN of the main S3 bucket"
  value       = aws_s3_bucket.main_bucket.arn
}

output "main_bucket_name" {
  description = "The name of the main S3 bucket"
  value       = aws_s3_bucket.main_bucket.bucket
}

output "log_bucket_id" {
  description = "The ID of the log S3 bucket"
  value       = aws_s3_bucket.log_bucket.id
}

output "log_bucket_arn" {
  description = "The ARN of the log S3 bucket"
  value       = aws_s3_bucket.log_bucket.arn
}

output "log_bucket_name" {
  description = "The name of the log S3 bucket"
  value       = aws_s3_bucket.log_bucket.bucket
}

output "folder_key" {
  description = "The key of the created folder"
  value       = aws_s3_object.app_folder.key
}
