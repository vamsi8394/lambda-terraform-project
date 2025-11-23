# S3 Bucket for storing logs (destination bucket)
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.log_bucket_name

  tags = merge(
    var.tags,
    {
      Name = "Log Storage Bucket"
    }
  )

  lifecycle {
    ignore_changes = [bucket]
  }
}

# Main S3 Bucket
resource "aws_s3_bucket" "main_bucket" {
  bucket = var.main_bucket_name

  tags = merge(
    var.tags,
    {
      Name = "Main Application Bucket"
    }
  )

  lifecycle {
    ignore_changes = [bucket]
  }
}

# Block all public access for main bucket
resource "aws_s3_bucket_public_access_block" "main_bucket_pab" {
  bucket = aws_s3_bucket.main_bucket.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Enable versioning for main bucket
resource "aws_s3_bucket_versioning" "main_bucket_versioning" {
  bucket = aws_s3_bucket.main_bucket.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# Enable server access logging for main bucket
resource "aws_s3_bucket_logging" "main_bucket_logging" {
  bucket = aws_s3_bucket.main_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = var.log_prefix
}

# Create a folder (prefix) in the main bucket
resource "aws_s3_object" "app_folder" {
  bucket       = aws_s3_bucket.main_bucket.id
  key          = var.folder_name
  content_type = "application/x-directory"
}

# Lifecycle rule for main bucket
resource "aws_s3_bucket_lifecycle_configuration" "main_bucket_lifecycle" {
  bucket = aws_s3_bucket.main_bucket.id

  rule {
    id     = var.lifecycle_rule_name
    status = "Enabled"

    # Apply to all objects in the bucket
    filter {}

    expiration {
      days = var.expiration_days
    }
  }
}
