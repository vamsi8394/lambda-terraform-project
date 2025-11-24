# Configuration Files

This directory contains YAML configuration files for the Lambda Terraform project.

## Files

### config.yml
Main configuration file containing:
- Project metadata
- AWS settings
- Lambda function configurations
- API Gateway settings
- WAF rules and IP sets
- S3 bucket configurations
- Step Functions and EventBridge settings
- Monitoring and tagging

### profiles.yml
Environment-specific profiles for:
- **dev** - Development environment with minimal resources
- **qa** - QA environment with production-like settings
- **prod** - Production environment with optimized resources

Each profile includes:
- Lambda memory and timeout settings
- API Gateway throttling limits
- S3 bucket names and lifecycle policies
- CloudWatch log retention
- Environment-specific tags

## Usage

These configuration files serve as:
1. **Documentation** - Central reference for all project settings
2. **CI/CD** - Can be parsed by scripts for automated deployments
3. **Consistency** - Ensures settings match across Terraform and application code

## Shared Configuration

The `shared` section in `profiles.yml` contains settings that are common across all environments:
- Jira base URL
- Secrets Manager ARN
- Bedrock model configuration
- Resource name prefixes

## Updating Configuration

When changing settings:
1. Update the YAML files first
2. Update corresponding Terraform variables
3. Update environment-specific `terraform.tfvars` files
4. Test in dev before promoting to qa/prod
