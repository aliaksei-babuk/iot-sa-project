#!/bin/bash

# Azure IoT Sound Analytics - Terraform Configuration Validation
# This script validates Terraform configuration without requiring full deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate Terraform syntax
validate_syntax() {
    print_header "Validating Terraform Syntax"
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        print_status "Installation instructions:"
        echo "  macOS: brew install terraform"
        echo "  Linux: https://developer.hashicorp.com/terraform/downloads"
        echo "  Windows: https://developer.hashicorp.com/terraform/downloads"
        return 1
    fi
    
    local tf_version=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    print_status "Terraform version: ${tf_version}"
    
    # Check for duplicate required_providers
    print_status "Checking for duplicate required_providers..."
    local provider_blocks=$(grep -r "required_providers" . --include="*.tf" | wc -l)
    if [ "$provider_blocks" -gt 1 ]; then
        print_error "Found multiple required_providers blocks. This will cause errors."
        print_status "Required providers should only be defined in versions.tf"
        grep -r "required_providers" . --include="*.tf" -n
        return 1
    else
        print_success "Only one required_providers block found"
    fi
    
    # Check for duplicate terraform blocks
    print_status "Checking for duplicate terraform blocks..."
    local terraform_blocks=$(grep -r "terraform {" . --include="*.tf" | wc -l)
    if [ "$terraform_blocks" -gt 1 ]; then
        print_error "Found multiple terraform blocks. This will cause errors."
        print_status "Terraform configuration should only be defined in versions.tf"
        grep -r "terraform {" . --include="*.tf" -n
        return 1
    else
        print_success "Only one terraform block found"
    fi
    
    # Validate Terraform configuration
    print_status "Running terraform validate..."
    if terraform init -backend=false >/dev/null 2>&1; then
        if terraform validate >/dev/null 2>&1; then
            print_success "Terraform configuration is valid"
            return 0
        else
            print_error "Terraform validation failed"
            print_status "Running terraform validate for details:"
            terraform validate
            return 1
        fi
    else
        print_error "Terraform init failed"
        print_status "Running terraform init for details:"
        terraform init -backend=false
        return 1
    fi
}

# Function to check configuration files
check_config_files() {
    print_header "Checking Configuration Files"
    
    local config_file="terraform.tfvars"
    
    if [ ! -f "${config_file}" ]; then
        print_warning "terraform.tfvars not found"
        if [ -d "config" ] && [ "$(ls -A config 2>/dev/null)" ]; then
            print_status "Available configurations in config/ directory:"
            ls -la config/*.tfvars 2>/dev/null || true
            print_status "Run: ./config-manager.sh switch <environment> to select a configuration"
        else
            print_status "Run: ./config-manager.sh setup <environment> to create a configuration"
        fi
        return 1
    else
        print_success "Configuration file found: ${config_file}"
        
        # Check if it's a symlink
        if [ -L "${config_file}" ]; then
            local target=$(readlink "${config_file}")
            print_status "Configuration is a symlink to: ${target}"
        fi
        
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
        else
            print_success "All required variables found in configuration"
        fi
    fi
}

# Function to check module structure
check_module_structure() {
    print_header "Checking Module Structure"
    
    local modules=("networking" "iot_services" "compute" "storage" "security" "monitoring" "analytics" "api")
    local missing_modules=()
    
    for module in "${modules[@]}"; do
        if [ -d "modules/${module}" ]; then
            if [ -f "modules/${module}/main.tf" ] && [ -f "modules/${module}/variables.tf" ] && [ -f "modules/${module}/outputs.tf" ]; then
                print_success "Module ${module}: Complete"
            else
                print_warning "Module ${module}: Missing required files (main.tf, variables.tf, outputs.tf)"
            fi
        else
            missing_modules+=("${module}")
        fi
    done
    
    if [ ${#missing_modules[@]} -ne 0 ]; then
        print_warning "Missing modules: ${missing_modules[*]}"
    fi
    
    print_success "Module structure check completed"
}

# Function to show help
show_help() {
    echo "Azure IoT Sound Analytics - Terraform Validation"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  validate    - Validate Terraform configuration (default)"
    echo "  syntax      - Check syntax and structure only"
    echo "  config      - Check configuration files only"
    echo "  modules     - Check module structure only"
    echo "  all         - Run all validation checks"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 validate"
    echo "  $0 syntax"
    echo "  $0 all"
}

# Main script logic
main() {
    case "${1:-validate}" in
        "validate")
            validate_syntax
            ;;
        "syntax")
            validate_syntax
            ;;
        "config")
            check_config_files
            ;;
        "modules")
            check_module_structure
            ;;
        "all")
            check_config_files
            check_module_structure
            validate_syntax
            ;;
        "help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
