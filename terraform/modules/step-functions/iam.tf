# IAM Role for Step Functions
resource "aws_iam_role" "state_machine" {
  count = var.create_role ? 1 : 0

  name = "${var.state_machine_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Comprehensive Policy for Step Functions
resource "aws_iam_role_policy" "state_machine_policy" {
  count = var.create_role ? 1 : 0

  name = "${var.state_machine_name}-policy"
  role = aws_iam_role.state_machine[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Sid    = "BedrockInvokeModels"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/amazon.nova-*",
          "arn:aws:bedrock:*:*:inference-profile/us.amazon.nova-*"
        ]
      },
      {
        Sid    = "AllowNativeHTTPInvokeToJira"
        Effect = "Allow"
        Action = "states:InvokeHTTPEndpoint"
        Resource = "*"
        Condition = {
          StringEquals = {
            "states:HTTPMethod" = "POST"
          }
          StringLike = {
            "states:HTTPEndpoint" = "${var.jira_base_url}/*"
          }
        }
      },
      {
        Sid    = "LambdaInvoke"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = var.lambda_function_arns
      },
      {
        Sid    = "AllowConnectionAccess"
        Effect = "Allow"
        Action = "events:RetrieveConnectionCredentials"
        Resource = var.eventbridge_connection_arns
      },
      {
        Sid    = "AllowSecretForConnection"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:events!connection/*"
      },
      {
        Sid    = "AllowSFNLoggingDelivery"
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:ListLogDeliveries"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSFNLogWriting"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
