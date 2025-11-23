#!/bin/bash

# Deployment script for Lambda Terraform project
# Usage: ./deploy.sh <environment>
# Example: ./deploy.sh dev

set -e

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment argument
if [ -z "$ENVIRONMENT" ]; then
    print_error "Environment not specified"
    echo "Usage: $0 <environment>"
    echo "Available environments: dev, qa, prod"
    exit 1
fi

# Validate environment exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    print_error "Environment '$ENVIRONMENT' not found"
    echo "Available environments: dev, qa, prod"
    exit 1
fi

print_info "Deploying to $ENVIRONMENT environment"
print_info "Terraform directory: $TERRAFORM_DIR"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform 1.5.7 or later."
    exit 1
fi

# Check Terraform version
TERRAFORM_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
print_info "Terraform version: $TERRAFORM_VERSION"

# Navigate to terraform directory
cd "$TERRAFORM_DIR"

# Initialize Terraform
print_info "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_info "Validating Terraform configuration..."
terraform validate

# Format check
print_info "Checking Terraform formatting..."
terraform fmt -check -recursive || {
    print_warn "Terraform files are not formatted. Running terraform fmt..."
    terraform fmt -recursive
}

# Plan
print_info "Creating Terraform plan..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_warn "Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply
print_info "Applying Terraform plan..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

# Output results
print_info "Deployment complete!"
echo ""
print_info "Outputs:"
terraform output

print_info "Deployment to $ENVIRONMENT completed successfully!"
