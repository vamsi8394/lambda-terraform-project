#!/bin/bash

# Validation script for Terraform configurations
# Usage: ./validate.sh [environment]
# If no environment specified, validates all environments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_BASE="$PROJECT_ROOT/terraform/environments"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

validate_environment() {
    local env=$1
    local env_dir="$TERRAFORM_BASE/$env"
    
    print_info "Validating $env environment..."
    
    cd "$env_dir"
    
    # Initialize
    terraform init -backend=false > /dev/null 2>&1
    
    # Validate
    if terraform validate; then
        print_success "$env environment validation passed"
    else
        print_error "$env environment validation failed"
        return 1
    fi
    
    # Format check
    if terraform fmt -check -recursive > /dev/null 2>&1; then
        print_success "$env environment formatting is correct"
    else
        print_error "$env environment has formatting issues"
        echo "Run: terraform fmt -recursive"
        return 1
    fi
    
    return 0
}

# Main
ENVIRONMENT=$1
FAILED=0

if [ -n "$ENVIRONMENT" ]; then
    # Validate specific environment
    if [ ! -d "$TERRAFORM_BASE/$ENVIRONMENT" ]; then
        print_error "Environment '$ENVIRONMENT' not found"
        exit 1
    fi
    
    validate_environment "$ENVIRONMENT" || FAILED=1
else
    # Validate all environments
    print_info "Validating all environments..."
    
    for env in dev qa prod; do
        if [ -d "$TERRAFORM_BASE/$env" ]; then
            validate_environment "$env" || FAILED=1
            echo ""
        fi
    done
fi

if [ $FAILED -eq 0 ]; then
    print_success "All validations passed!"
    exit 0
else
    print_error "Some validations failed"
    exit 1
fi
