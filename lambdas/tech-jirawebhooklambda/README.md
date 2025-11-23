# tech-jirawebhooklambda

AWS Lambda function that processes Jira webhook events for contract attachments.

## Purpose

This Lambda function:
- Receives webhook events from Jira when attachments are added to issues
- Validates HMAC signatures for security
- Downloads PDF and DOCX files from Jira
- Uploads files to S3 with metadata
- Triggers Step Functions workflow for text extraction

## Runtime Configuration

- **Runtime**: Python 3.13
- **Architecture**: arm64
- **Memory**: 512 MB
- **Ephemeral Storage**: 512 MB
- **Timeout**: 90 seconds

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `JIRA_BASE_URL` | Jira instance base URL | `https://pilotflyingj-sandbox-951.atlassian.net` |
| `JIRA_CONNECTION_ARN` | EventBridge connection ARN for Jira | `arn:aws:events:us-east-1:...` |
| `STATE_MACHINE_ARN` | Step Functions state machine ARN | `arn:aws:states:us-east-1:...` |
| `S3_BUCKET_NAME` | S3 bucket for storing contracts | `pfj-legal-tech-contracts-bucket` |
| `SECRETS_ARN` | Secrets Manager ARN for Jira credentials | `arn:aws:secretsmanager:us-east-1:...` |

## Secrets Manager Configuration

The Lambda requires a secret with the following keys:
```json
{
  "jiraEmail": "your-email@example.com",
  "jiraApiToken": "your-jira-api-token",
  "webhookSecret": "your-webhook-secret"
}
```

## IAM Permissions Required

- `s3:PutObject`, `s3:PutObjectAcl` on S3 bucket
- `secretsmanager:GetSecretValue` on secrets
- `states:StartExecution` on Step Functions
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

## Trigger

- **API Gateway**: REST API
- **Method**: POST
- **Path**: `/webhook`
- **Authorization**: NONE (uses HMAC signature verification)

## File Validation

- **Allowed Extensions**: PDF, DOCX
- **Max File Size**: 50 MB
- **Security**: SSRF protection, private IP blocking, hostname validation

## Deployment

See the main project README for deployment instructions using Terraform.
