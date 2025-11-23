# Lambda Terraform Project

AWS Lambda functions deployed with Terraform for multi-environment infrastructure (dev, qa, prod).

## Project Overview

This project contains:
- **tech-jirawebhooklambda**: Processes Jira webhook events for contract attachments
- **tech-extracttextlambda**: Extracts text from documents (to be added)

## Architecture

```
Jira Webhook → API Gateway → Lambda (tech-jirawebhooklambda) → S3 + Step Functions
                                                                    ↓
                                                          Lambda (tech-extracttextlambda)
```

## Prerequisites

- **Terraform**: >= 1.5.7
- **AWS CLI**: Configured with appropriate credentials
- **Python**: 3.13 (for local testing)
- **AWS Account**: With permissions to create Lambda, API Gateway, IAM, CloudWatch resources

## Project Structure

```
lambda-terraform-project/
├── lambdas/
│   ├── tech-jirawebhooklambda/      # Jira webhook processor
│   └── tech-extracttextlambda/      # Text extraction (TBD)
├── terraform/
│   ├── modules/
│   │   ├── lambda/                  # Reusable Lambda module
│   │   └── api-gateway/             # Reusable API Gateway module
│   └── environments/
│       ├── dev/                     # Development environment
│       ├── qa/                      # QA environment
│       └── prod/                    # Production environment
├── scripts/
│   ├── deploy.sh                    # Deployment script
│   ├── validate.sh                  # Validation script
│   └── destroy.sh                   # Cleanup script
└── README.md
```

## Quick Start

### 1. Clone and Navigate

```bash
cd lambda-terraform-project
```

### 2. Review Configuration

Edit the environment-specific `terraform.tfvars` files:
- `terraform/environments/dev/terraform.tfvars`
- `terraform/environments/qa/terraform.tfvars`
- `terraform/environments/prod/terraform.tfvars`

Update the `aws_account_id` and any ARNs specific to your AWS account.

### 3. Deploy to Dev

```bash
./scripts/deploy.sh dev
```

This will:
1. Initialize Terraform
2. Validate configuration
3. Create a plan
4. Ask for confirmation
5. Apply the changes

### 4. Get Outputs

After deployment, Terraform will output:
- Lambda function ARN
- API Gateway endpoint URL
- CloudWatch log group names

```bash
cd terraform/environments/dev
terraform output
```

## Deployment

### Deploy to Specific Environment

```bash
# Development
./scripts/deploy.sh dev

# QA
./scripts/deploy.sh qa

# Production
./scripts/deploy.sh prod
```

### Validate Configuration

```bash
# Validate all environments
./scripts/validate.sh

# Validate specific environment
./scripts/validate.sh dev
```

### Destroy Resources

```bash
./scripts/destroy.sh dev
```

## Environment Differences

| Environment | Memory | Timeout | Log Retention |
|-------------|--------|---------|---------------|
| **Dev**     | 512 MB | 90s     | 7 days        |
| **QA**      | 1024 MB| 90s     | 14 days       |
| **Prod**    | 1024 MB| 90s     | 30 days       |

## Lambda Functions

### tech-jirawebhooklambda

**Purpose**: Receives Jira webhook events, downloads attachments, uploads to S3, and triggers Step Functions.

**Trigger**: API Gateway (POST /webhook)

**Environment Variables**:
- `JIRA_BASE_URL`
- `JIRA_CONNECTION_ARN`
- `STATE_MACHINE_ARN`
- `S3_BUCKET_NAME`
- `SECRETS_ARN`

**IAM Permissions**:
- S3: PutObject
- Secrets Manager: GetSecretValue
- Step Functions: StartExecution
- CloudWatch Logs: CreateLogGroup, CreateLogStream, PutLogEvents

See [lambdas/tech-jirawebhooklambda/README.md](lambdas/tech-jirawebhooklambda/README.md) for details.

## Terraform Modules

### Lambda Module

Reusable module for creating Lambda functions with:
- Automatic ZIP packaging
- IAM role and policies
- CloudWatch log groups
- Environment variables
- Configurable runtime, memory, timeout

### API Gateway Module

Reusable module for creating API Gateway with:
- REST API
- Lambda integration
- Deployment and stage
- Invoke permissions

## Manual Terraform Commands

If you prefer not to use the scripts:

```bash
cd terraform/environments/dev

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy
```

## Terraform State

Currently configured for **local state**. For production use, configure S3 backend:

1. Create S3 bucket and DynamoDB table for state locking
2. Uncomment and configure the `backend "s3"` block in `backend.tf`
3. Run `terraform init -migrate-state`

## Updating Lambda Code

1. Modify the Lambda function code in `lambdas/tech-jirawebhooklambda/lambda_function.py`
2. Run deployment script:
   ```bash
   ./scripts/deploy.sh dev
   ```
3. Terraform will detect the code change and update the Lambda function

## Monitoring

### CloudWatch Logs

Logs are available in CloudWatch:
- `/aws/lambda/tech-jirawebhooklambda-dev`
- `/aws/lambda/tech-jirawebhooklambda-qa`
- `/aws/lambda/tech-jirawebhooklambda-prod`

### View Logs

```bash
aws logs tail /aws/lambda/tech-jirawebhooklambda-dev --follow
```

## Testing

### Test API Gateway Endpoint

```bash
# Get the endpoint URL
cd terraform/environments/dev
terraform output webhook_api_endpoint

# Test with curl (requires valid Jira webhook payload and signature)
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/stage1/webhook \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=YOUR-SIGNATURE" \
  -d '{"webhookEvent": "jira:issue_updated", ...}'
```

## Troubleshooting

### Terraform Init Fails

- Ensure Terraform 1.5.7+ is installed
- Check AWS credentials are configured

### Lambda Deployment Fails

- Verify IAM permissions
- Check CloudWatch logs for errors
- Ensure all environment variables are set correctly

### API Gateway Returns 403

- Verify HMAC signature is correct
- Check Secrets Manager has correct webhook secret

## Security

- HMAC signature verification for webhook authenticity
- SSRF protection with hostname and IP validation
- Secrets stored in AWS Secrets Manager
- S3 server-side encryption (AES256)
- Private IP range blocking
- CloudWatch logs for audit trail

## Contributing

When adding new Lambda functions:
1. Create directory in `lambdas/`
2. Add Lambda code and `requirements.txt`
3. Update `terraform/environments/*/main.tf` to include new Lambda module
4. Update this README

## License

[Your License Here]

## Support

For issues or questions, please contact [Your Contact Info]
