# Terraform Infrastructure

This directory contains Terraform configurations for deploying AWS Lambda functions across multiple environments.

## Directory Structure

```
terraform/
├── modules/
│   ├── lambda/              # Reusable Lambda module
│   └── api-gateway/         # Reusable API Gateway module
└── environments/
    ├── dev/                 # Development environment
    ├── qa/                  # QA environment
    └── prod/                # Production environment
```

## Modules

### Lambda Module

Creates a Lambda function with:
- Automatic source code packaging (ZIP)
- IAM execution role with customizable policies
- CloudWatch log group with configurable retention
- Environment variables
- Configurable runtime, memory, timeout, architecture

**Usage**:
```hcl
module "my_lambda" {
  source = "../../modules/lambda"

  function_name    = "my-function"
  runtime          = "python3.13"
  architecture     = "arm64"
  memory_size      = 512
  timeout          = 90
  source_dir       = "${path.module}/../../../lambdas/my-function"
  
  environment_variables = {
    KEY = "value"
  }
  
  iam_policy_statements = [
    {
      sid       = "AllowS3"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::my-bucket/*"]
    }
  ]
}
```

### API Gateway Module

Creates a REST API Gateway with Lambda integration:
- REST API with regional endpoint
- Resource and method configuration
- Lambda proxy integration
- Deployment and stage
- Lambda invoke permissions

**Usage**:
```hcl
module "my_api" {
  source = "../../modules/api-gateway"

  api_name             = "my-api"
  lambda_invoke_arn    = module.my_lambda.invoke_arn
  lambda_function_name = module.my_lambda.function_name
  resource_path        = "webhook"
  http_method          = "POST"
}
```

## Environments

Each environment has its own directory with:
- `backend.tf` - Terraform and provider configuration
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Environment-specific values
- `main.tf` - Resource definitions
- `outputs.tf` - Output values

### Environment Configuration

| File | Purpose |
|------|---------|
| `backend.tf` | Terraform version, provider requirements, backend config |
| `variables.tf` | Variable declarations with types and defaults |
| `terraform.tfvars` | Actual values for the environment |
| `main.tf` | Module instantiations and resource definitions |
| `outputs.tf` | Exported values (ARNs, URLs, etc.) |

## Deployment

### Initialize

```bash
cd environments/dev
terraform init
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

### Destroy

```bash
terraform destroy
```

## State Management

### Local State (Current)

State files are stored locally in each environment directory. **Not recommended for production**.

### Remote State (Recommended)

For production, configure S3 backend:

1. Create S3 bucket:
```bash
aws s3 mb s3://your-terraform-state-bucket
```

2. Create DynamoDB table for locking:
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

3. Uncomment backend configuration in `backend.tf`:
```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "lambda-project/dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

4. Migrate state:
```bash
terraform init -migrate-state
```

## Adding New Resources

### Add a New Lambda Function

1. Create Lambda code in `lambdas/new-function/`
2. Add module in `environments/*/main.tf`:
```hcl
module "new_function" {
  source = "../../modules/lambda"
  
  function_name = "new-function-${var.environment}"
  source_dir    = "${local.lambda_source_dir}/new-function"
  # ... other configuration
}
```

3. Add outputs in `environments/*/outputs.tf`:
```hcl
output "new_function_arn" {
  value = module.new_function.function_arn
}
```

## Best Practices

1. **Use Modules**: Keep code DRY by using reusable modules
2. **Environment Separation**: Maintain separate state files per environment
3. **Remote State**: Use S3 backend with state locking for production
4. **Version Control**: Commit Terraform code, never commit state files
5. **Plan Before Apply**: Always review `terraform plan` output
6. **Tag Resources**: Use consistent tagging for cost tracking
7. **Least Privilege**: Grant minimal IAM permissions needed

## Troubleshooting

### State Lock Issues

If state is locked:
```bash
terraform force-unlock <LOCK_ID>
```

### Module Not Found

Ensure you're in the correct directory:
```bash
cd terraform/environments/dev
```

### Provider Plugin Issues

Re-initialize:
```bash
rm -rf .terraform
terraform init
```

## Terraform Version

- **Required**: >= 1.5.7
- **AWS Provider**: ~> 6.0

## Variables Reference

See `variables.tf` in each environment for full variable documentation.

Common variables:
- `aws_region` - AWS region (default: us-east-1)
- `environment` - Environment name (dev/qa/prod)
- `aws_account_id` - AWS account ID
- `*_lambda_memory` - Lambda memory allocation
- `*_lambda_timeout` - Lambda timeout in seconds
- `*_lambda_log_retention` - CloudWatch log retention days
