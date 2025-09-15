#!/bin/bash

# Test validation logic without prerequisites check

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test validation logic
TERRAFORM_DIR="$(pwd)"
CONFIG_DIR="${TERRAFORM_DIR}/config"

validate_config() {
    echo "=========================================="
    echo " Testing Configuration Validation"
    echo "=========================================="
    
    local config_file="${TERRAFORM_DIR}/terraform.tfvars"
    
    # Check if terraform.tfvars exists (symlink or file)
    if [ ! -f "${config_file}" ]; then
        # Check if there are any config files in the config directory
        if [ -d "${CONFIG_DIR}" ] && [ "$(ls -A ${CONFIG_DIR} 2>/dev/null)" ]; then
            print_warning "terraform.tfvars not found, but configuration files exist in config/ directory"
            print_status "Available configurations:"
            ls -la "${CONFIG_DIR}"/*.tfvars 2>/dev/null || true
            print_status "Please run: ./config-manager.sh switch <environment> to select a configuration"
            return 1
        else
            print_error "terraform.tfvars not found and no configuration files exist"
            print_status "Please run: ./config-manager.sh setup <environment> to create a configuration"
            return 1
        fi
    fi
    
    print_success "Configuration file found: ${config_file}"
    
    # Validate required variables
    local required_vars=("environment" "location" "admin_email")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}.*=" "${config_file}"; then
            missing_vars+=("${var}")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing required variables: ${missing_vars[*]}"
        return 1
    fi
    
    # Validate environment
    local environment=$(grep "^environment" "${config_file}" | cut -d'"' -f2)
    if [[ ! "$environment" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Invalid environment: ${environment}. Must be dev, staging, or prod"
        return 1
    fi
    
    print_success "Configuration validation passed"
    return 0
}

# Run the test
validate_config
