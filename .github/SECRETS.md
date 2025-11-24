# GitHub Actions Secrets Required

To use the Terraform CI/CD workflows, you need to configure the following secrets in your GitHub repository:

## Required Secrets

### AWS Credentials
- **AWS_ACCESS_KEY_ID** - AWS access key for Terraform deployments
- **AWS_SECRET_ACCESS_KEY** - AWS secret access key

### Jira Credentials
- **JIRA_EMAIL** - Jira user email for EventBridge connection
- **JIRA_API_TOKEN** - Jira API token for authentication

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name listed above

## AWS IAM Permissions Required

The AWS credentials should have permissions for:
- Lambda (create, update, delete functions and layers)
- API Gateway (create, update, delete APIs)
- IAM (create, update, delete roles and policies)
- S3 (create, update, delete buckets and objects)
- Step Functions (create, update, delete state machines)
- EventBridge (create, update, delete connections)
- WAF (create, update, delete web ACLs and IP sets)
- CloudWatch Logs (create, update, delete log groups)
- Secrets Manager (read secrets)

## Environment Protection Rules

For production deployments, consider adding environment protection rules:

1. Go to **Settings** → **Environments**
2. Create environments: `dev`, `qa`, `prod`
3. For `prod`, add:
   - Required reviewers
   - Wait timer (e.g., 5 minutes)
   - Deployment branches (only `main`)

## Terraform Backend

Make sure your S3 backend bucket and DynamoDB table exist before running workflows:

```bash
# Create S3 bucket for state
aws s3 mb s3://terraform-state-lambda-project

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```
