#!/bin/bash

# Azure IoT Sound Analytics - Configuration Manager
# This script helps manage configuration files and environment setup

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

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

# Function to create environment-specific configuration
create_environment_config() {
    local environment="$1"
    
    print_header "Creating Configuration for ${environment}"
    
    if [[ ! "$environment" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Environment must be one of: dev, staging, prod"
        exit 1
    fi
    
    local config_file="${CONFIG_DIR}/terraform-${environment}.tfvars"
    local template_file="${TEMPLATES_DIR}/terraform-${environment}.tfvars.template"
    
    # Create templates directory if it doesn't exist
    mkdir -p "${TEMPLATES_DIR}"
    
    # Create template if it doesn't exist
    if [ ! -f "${template_file}" ]; then
        print_status "Creating template for ${environment}..."
        cat > "${template_file}" << EOF
# Azure IoT Sound Analytics - ${environment^} Environment Configuration
# Generated on $(date)

# Environment Configuration
environment = "${environment}"
location    = "East US"

# Networking Configuration
vnet_address_space = ["10.0.0.0/16"]

subnet_configs = {
  "public" = {
    address_prefixes  = ["10.0.1.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  }
  "private-compute" = {
    address_prefixes  = ["10.0.2.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ServiceBus"]
  }
  "private-data" = {
    address_prefixes  = ["10.0.3.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]
  }
  "private-integration" = {
    address_prefixes  = ["10.0.4.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ServiceBus"]
  }
}

# IoT Services Configuration
iot_hub_sku      = "S1"
iot_hub_capacity = 1

# Storage Configuration
cosmos_db_throughput = 400
sql_database_sku     = "S0"

# Compute Configuration
function_app_plan_sku           = "Y1"
container_app_environment_sku   = "Consumption"

# Security Configuration
enable_security_center = true
enable_ddos_protection = false

# Monitoring Configuration
enable_monitoring = true
retention_days    = 30
backup_retention_days = 7

# Notification Configuration
admin_email = "admin@yourcompany.com"
notification_phone = "+1234567890"

# Network Security
allowed_ip_addresses = [
  "203.0.113.0/24",
  "198.51.100.0/24"
]

# Private Endpoints
enable_private_endpoints = true

# Encryption
enable_encryption_at_rest  = true
enable_encryption_in_transit = true
enable_audit_logging = true

# Compliance Standards
compliance_standards = ["GDPR", "SOC2", "ISO27001"]

# API Management Configuration
api_management_sku = "Developer_1"
publisher_name     = "Your Company"
publisher_email    = "admin@yourcompany.com"

# Analytics Configuration
enable_power_bi = false
enable_synapse  = false

# SQL Server Configuration
sql_admin_username = "sqladmin"
sql_admin_password = "YourSecurePassword123!"

# Azure AD Configuration
azure_ad_admin_login      = "admin@yourcompany.com"
azure_ad_admin_object_id  = "00000000-0000-0000-0000-000000000000"

# Security Contact Information
security_contact_email = "security@yourcompany.com"
security_contact_phone = "+1234567890"
EOF
        print_success "Template created: ${template_file}"
    fi
    
    # Copy template to config
    cp "${template_file}" "${config_file}"
    
    # Update with current Azure context
    local current_subscription=$(az account show --query "name" -o tsv 2>/dev/null || echo "Unknown")
    local current_tenant=$(az account show --query "tenantId" -o tsv 2>/dev/null || echo "Unknown")
    local current_user=$(az account show --query "user.name" -o tsv 2>/dev/null || echo "Unknown")
    
    # Update admin email
    sed -i "s/admin_email = \"admin@yourcompany.com\"/admin_email = \"${current_user}\"/" "${config_file}"
    
    # Update Azure AD admin object ID
    local object_id=$(az ad signed-in-user show --query "id" -o tsv 2>/dev/null || echo "00000000-0000-0000-0000-000000000000")
    sed -i "s/azure_ad_admin_object_id = \"00000000-0000-0000-0000-000000000000\"/azure_ad_admin_object_id = \"${object_id}\"/" "${config_file}"
    
    print_success "Configuration created: ${config_file}"
    print_status "Please review and customize the configuration before deployment"
}

# Function to validate configuration
validate_config() {
    local config_file="$1"
    
    if [ ! -f "${config_file}" ]; then
        print_error "Configuration file not found: ${config_file}"
        exit 1
    fi
    
    print_header "Validating Configuration: ${config_file}"
    
    # Check required variables
    local required_vars=("environment" "location" "admin_email")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}.*=" "${config_file}"; then
            missing_vars+=("${var}")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing required variables: ${missing_vars[*]}"
        exit 1
    fi
    
    # Validate environment
    local environment=$(grep "^environment" "${config_file}" | cut -d'"' -f2)
    if [[ ! "$environment" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Invalid environment: ${environment}. Must be dev, staging, or prod"
        exit 1
    fi
    
    # Validate location
    local location=$(grep "^location" "${config_file}" | cut -d'"' -f2)
    if [ -z "$location" ]; then
        print_error "Location not specified"
        exit 1
    fi
    
    # Validate email format
    local admin_email=$(grep "^admin_email" "${config_file}" | cut -d'"' -f2)
    if [[ ! "$admin_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_warning "Admin email format may be invalid: ${admin_email}"
    fi
    
    print_success "Configuration validation passed"
}

# Function to generate secure passwords
generate_passwords() {
    print_header "Generating Secure Passwords"
    
    local password_file="${CONFIG_DIR}/passwords.txt"
    
    print_status "Generating secure passwords..."
    
    cat > "${password_file}" << EOF
# Azure IoT Sound Analytics - Generated Passwords
# Generated on $(date)
# Keep this file secure and do not commit to version control

# SQL Server Admin Password
SQL_ADMIN_PASSWORD=$(openssl rand -base64 32)

# Azure AD Admin Password (if using password auth)
AZURE_AD_ADMIN_PASSWORD=$(openssl rand -base64 32)

# Application Secrets
APP_SECRET_KEY=$(openssl rand -base64 32)
JWT_SECRET_KEY=$(openssl rand -base64 32)

# Database Connection Strings
# Update these in your terraform.tfvars after deployment
EOF
    
    print_success "Passwords generated: ${password_file}"
    print_warning "Keep this file secure and do not commit to version control"
}

# Function to setup environment
setup_environment() {
    local environment="$1"
    
    print_header "Setting Up Environment: ${environment}"
    
    # Create configuration
    create_environment_config "$environment"
    
    # Generate passwords
    generate_passwords
    
    # Create symlink for active config
    local config_file="${CONFIG_DIR}/terraform-${environment}.tfvars"
    local active_config="terraform.tfvars"
    
    if [ -L "${active_config}" ]; then
        rm "${active_config}"
    fi
    
    ln -s "${config_file}" "${active_config}"
    
    print_success "Environment setup completed"
    print_status "Active configuration: ${config_file}"
    print_status "Next steps:"
    echo "  1. Review and customize ${config_file}"
    echo "  2. Update passwords in ${CONFIG_DIR}/passwords.txt"
    echo "  3. Run: ./deploy-azure.sh deploy"
}

# Function to list configurations
list_configurations() {
    print_header "Available Configurations"
    
    if [ ! -d "${CONFIG_DIR}" ]; then
        print_warning "No configurations found"
        return
    fi
    
    for config in "${CONFIG_DIR}"/terraform-*.tfvars; do
        if [ -f "$config" ]; then
            local env=$(basename "$config" | sed 's/terraform-\(.*\)\.tfvars/\1/')
            local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$config" 2>/dev/null || stat -c "%y" "$config" 2>/dev/null || echo "Unknown")
            echo "  ${env}: ${config} (modified: ${modified})"
        fi
    done
}

# Function to switch environment
switch_environment() {
    local environment="$1"
    
    print_header "Switching to Environment: ${environment}"
    
    local config_file="${CONFIG_DIR}/terraform-${environment}.tfvars"
    
    if [ ! -f "${config_file}" ]; then
        print_error "Configuration not found: ${config_file}"
        print_status "Run 'create ${environment}' to create the configuration first"
        exit 1
    fi
    
    # Remove existing symlink
    if [ -L "terraform.tfvars" ]; then
        rm "terraform.tfvars"
    fi
    
    # Create new symlink
    ln -s "${config_file}" "terraform.tfvars"
    
    print_success "Switched to ${environment} environment"
    print_status "Active configuration: ${config_file}"
}

# Function to backup configuration
backup_configuration() {
    local environment="$1"
    
    print_header "Backing Up Configuration: ${environment}"
    
    local config_file="${CONFIG_DIR}/terraform-${environment}.tfvars"
    local backup_file="${CONFIG_DIR}/backup-${environment}-$(date +%Y%m%d-%H%M%S).tfvars"
    
    if [ ! -f "${config_file}" ]; then
        print_error "Configuration not found: ${config_file}"
        exit 1
    fi
    
    cp "${config_file}" "${backup_file}"
    
    print_success "Configuration backed up: ${backup_file}"
}

# Function to restore configuration
restore_configuration() {
    local backup_file="$1"
    
    print_header "Restoring Configuration: ${backup_file}"
    
    if [ ! -f "${backup_file}" ]; then
        print_error "Backup file not found: ${backup_file}"
        exit 1
    fi
    
    local environment=$(basename "$backup_file" | sed 's/backup-\(.*\)-[0-9]\{8\}-[0-9]\{6\}\.tfvars/\1/')
    local config_file="${CONFIG_DIR}/terraform-${environment}.tfvars"
    
    cp "${backup_file}" "${config_file}"
    
    print_success "Configuration restored: ${config_file}"
}

# Function to display help
show_help() {
    echo "Azure IoT Sound Analytics - Configuration Manager"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create <env>         - Create configuration for environment (dev|staging|prod)"
    echo "  validate <file>      - Validate configuration file"
    echo "  setup <env>          - Setup complete environment"
    echo "  list                 - List available configurations"
    echo "  switch <env>         - Switch to environment"
    echo "  backup <env>         - Backup configuration"
    echo "  restore <file>       - Restore from backup"
    echo "  generate-passwords   - Generate secure passwords"
    echo "  help                 - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create dev"
    echo "  $0 setup prod"
    echo "  $0 switch staging"
    echo "  $0 validate config/terraform-dev.tfvars"
    echo "  $0 backup dev"
    echo "  $0 restore config/backup-dev-20240101-120000.tfvars"
}

# Main script logic
main() {
    # Create necessary directories
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${TEMPLATES_DIR}"
    
    local command="${1:-help}"
    
    case "$command" in
        "create")
            if [ -z "$2" ]; then
                print_error "Environment required"
                show_help
                exit 1
            fi
            create_environment_config "$2"
            ;;
        "validate")
            if [ -z "$2" ]; then
                print_error "Configuration file required"
                show_help
                exit 1
            fi
            validate_config "$2"
            ;;
        "setup")
            if [ -z "$2" ]; then
                print_error "Environment required"
                show_help
                exit 1
            fi
            setup_environment "$2"
            ;;
        "list")
            list_configurations
            ;;
        "switch")
            if [ -z "$2" ]; then
                print_error "Environment required"
                show_help
                exit 1
            fi
            switch_environment "$2"
            ;;
        "backup")
            if [ -z "$2" ]; then
                print_error "Environment required"
                show_help
                exit 1
            fi
            backup_configuration "$2"
            ;;
        "restore")
            if [ -z "$2" ]; then
                print_error "Backup file required"
                show_help
                exit 1
            fi
            restore_configuration "$2"
            ;;
        "generate-passwords")
            generate_passwords
            ;;
        "help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
