#!/bin/bash

# Destroy script for Lambda Terraform project
# Usage: ./destroy.sh <environment>
# Example: ./destroy.sh dev

set -e

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
if [ -z "$ENVIRONMENT" ]; then
    print_error "Environment not specified"
    echo "Usage: $0 <environment>"
    exit 1
fi

if [ ! -d "$TERRAFORM_DIR" ]; then
    print_error "Environment '$ENVIRONMENT' not found"
    exit 1
fi

# Warning
print_warn "WARNING: This will destroy all resources in the $ENVIRONMENT environment!"
echo ""
read -p "Are you absolutely sure? Type '$ENVIRONMENT' to confirm: " CONFIRM

if [ "$CONFIRM" != "$ENVIRONMENT" ]; then
    print_info "Destruction cancelled"
    exit 0
fi

cd "$TERRAFORM_DIR"

print_info "Destroying $ENVIRONMENT environment..."
terraform destroy

print_info "Destruction complete!"
