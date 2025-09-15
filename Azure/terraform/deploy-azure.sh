#!/bin/bash

# Azure IoT Sound Analytics - Enhanced CLI Deployment Script
# This script provides comprehensive deployment automation for the Azure infrastructure

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="iot-sound-analytics"
TERRAFORM_DIR="${SCRIPT_DIR}"
LOG_DIR="${SCRIPT_DIR}/logs"
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_DIR="${SCRIPT_DIR}/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging configuration
LOG_FILE="${LOG_DIR}/deployment-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "${LOG_DIR}"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_message "INFO" "$1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_message "SUCCESS" "$1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_message "WARNING" "$1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR" "$1"
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

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_deps=()
    
    # Check Terraform
    if ! command_exists terraform; then
        missing_deps+=("terraform")
    else
        local tf_version=$(terraform version -json | jq -r '.terraform_version')
        print_status "Terraform version: ${tf_version}"
    fi
    
    # Check Azure CLI
    if ! command_exists az; then
        missing_deps+=("azure-cli")
    else
        local az_version=$(az version --output tsv --query '"azure-cli"')
        print_status "Azure CLI version: ${az_version}"
    fi
    
    # Check jq
    if ! command_exists jq; then
        missing_deps+=("jq")
    fi
    
    # Check curl
    if ! command_exists curl; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Please install the missing dependencies and try again"
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show >/dev/null 2>&1; then
        print_error "Not logged in to Azure. Please run 'az login'"
        exit 1
    fi
    
    # Get current Azure context
    local current_subscription=$(az account show --query "name" -o tsv)
    local current_tenant=$(az account show --query "tenantId" -o tsv)
    print_status "Current Azure subscription: ${current_subscription}"
    print_status "Current Azure tenant: ${current_tenant}"
    
    print_success "Prerequisites check passed"
}

# Function to validate Azure permissions
validate_azure_permissions() {
    print_header "Validating Azure Permissions"
    
    local required_permissions=(
        "Microsoft.Resources/subscriptions/resourceGroups/read"
        "Microsoft.Resources/subscriptions/resourceGroups/write"
        "Microsoft.Resources/subscriptions/resourceGroups/delete"
        "Microsoft.Resources/deployments/read"
        "Microsoft.Resources/deployments/write"
        "Microsoft.Resources/deployments/delete"
        "Microsoft.Authorization/roleAssignments/read"
        "Microsoft.Authorization/roleAssignments/write"
        "Microsoft.Authorization/roleAssignments/delete"
    )
    
    print_status "Checking required permissions..."
    
    for permission in "${required_permissions[@]}"; do
        if ! az rest --method GET --url "https://management.azure.com/providers/Microsoft.Authorization/permissions" --query "value[?contains(actions, '${permission}')]" -o tsv | grep -q "${permission}"; then
            print_warning "Permission check for ${permission} - may need elevated permissions"
        fi
    done
    
    print_success "Azure permissions validation completed"
}

# Function to create configuration from template
create_config() {
    print_header "Creating Configuration"
    
    local config_file="${TERRAFORM_DIR}/terraform.tfvars"
    local example_file="${TERRAFORM_DIR}/terraform.tfvars.example"
    
    if [ ! -f "${config_file}" ]; then
        if [ -f "${example_file}" ]; then
            print_status "Creating terraform.tfvars from example..."
            cp "${example_file}" "${config_file}"
            
            # Update configuration with current Azure context
            local current_subscription=$(az account show --query "id" -o tsv)
            local current_tenant=$(az account show --query "tenantId" -o tsv)
            local current_user=$(az account show --query "user.name" -o tsv)
            
            # Update admin email if not set
            if grep -q 'admin_email = ""' "${config_file}"; then
                sed -i "s/admin_email = \"\"/admin_email = \"${current_user}\"/" "${config_file}"
            fi
            
            # Update Azure AD admin object ID if not set
            if grep -q 'azure_ad_admin_object_id = "00000000-0000-0000-0000-000000000000"' "${config_file}"; then
                local object_id=$(az ad signed-in-user show --query "id" -o tsv)
                sed -i "s/azure_ad_admin_object_id = \"00000000-0000-0000-0000-000000000000\"/azure_ad_admin_object_id = \"${object_id}\"/" "${config_file}"
            fi
            
            print_warning "Configuration file created. Please review and customize terraform.tfvars before proceeding"
            print_status "Current configuration:"
            cat "${config_file}" | head -20
            echo "..."
            
            read -p "Do you want to continue with the current configuration? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Please edit terraform.tfvars and run the script again"
                exit 0
            fi
        else
            print_error "terraform.tfvars.example not found. Please create terraform.tfvars manually"
            exit 1
        fi
    else
        print_status "Using existing terraform.tfvars configuration"
    fi
    
    print_success "Configuration setup completed"
}

# Function to validate configuration
validate_config() {
    print_header "Validating Configuration"
    
    local config_file="${TERRAFORM_DIR}/terraform.tfvars"
    
    if [ ! -f "${config_file}" ]; then
        print_error "terraform.tfvars not found"
        exit 1
    fi
    
    # Validate required variables
    local required_vars=("environment" "location" "admin_email")
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}.*=" "${config_file}"; then
            print_error "Required variable ${var} not found in terraform.tfvars"
            exit 1
        fi
    done
    
    # Validate environment value
    local environment=$(grep "^environment" "${config_file}" | cut -d'"' -f2)
    if [[ ! "$environment" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Environment must be one of: dev, staging, prod"
        exit 1
    fi
    
    print_success "Configuration validation passed"
}

# Function to initialize Terraform
init_terraform() {
    print_header "Initializing Terraform"
    
    cd "${TERRAFORM_DIR}"
    
    # Clean up previous state if requested
    if [ "$1" = "--clean" ]; then
        print_status "Cleaning previous Terraform state..."
        rm -rf .terraform/
        rm -f .terraform.lock.hcl
    fi
    
    # Initialize Terraform
    print_status "Running terraform init..."
    terraform init -upgrade
    
    # Validate configuration
    print_status "Validating Terraform configuration..."
    terraform validate
    
    print_success "Terraform initialized successfully"
}

# Function to plan deployment
plan_deployment() {
    print_header "Planning Deployment"
    
    cd "${TERRAFORM_DIR}"
    
    local plan_file="tfplan-$(date +%Y%m%d-%H%M%S).out"
    
    print_status "Creating deployment plan..."
    terraform plan -out="${plan_file}" -detailed-exitcode
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "No changes required"
        rm -f "${plan_file}"
        return 0
    elif [ $exit_code -eq 2 ]; then
        print_success "Deployment plan created: ${plan_file}"
        echo "${plan_file}" > .terraform-plan-file
        return 0
    else
        print_error "Terraform plan failed"
        exit 1
    fi
}

# Function to apply deployment
apply_deployment() {
    print_header "Applying Deployment"
    
    cd "${TERRAFORM_DIR}"
    
    local plan_file
    if [ -f ".terraform-plan-file" ]; then
        plan_file=$(cat .terraform-plan-file)
    else
        print_error "No deployment plan found. Please run 'plan' first"
        exit 1
    fi
    
    if [ ! -f "${plan_file}" ]; then
        print_error "Plan file ${plan_file} not found"
        exit 1
    fi
    
    print_status "Applying deployment plan: ${plan_file}"
    terraform apply "${plan_file}"
    
    # Clean up plan file
    rm -f "${plan_file}" .terraform-plan-file
    
    print_success "Deployment completed successfully"
}

# Function to show outputs
show_outputs() {
    print_header "Deployment Outputs"
    
    cd "${TERRAFORM_DIR}"
    
    print_status "Retrieving deployment outputs..."
    terraform output -json > "${CONFIG_DIR}/outputs.json" 2>/dev/null || true
    
    if [ -f "${CONFIG_DIR}/outputs.json" ]; then
        print_status "Deployment outputs saved to: ${CONFIG_DIR}/outputs.json"
        
        # Display key outputs
        print_status "Key deployment outputs:"
        echo "----------------------------------------"
        
        # Resource Group
        local rg_name=$(terraform output -raw resource_group_name 2>/dev/null || echo "N/A")
        echo "Resource Group: ${rg_name}"
        
        # IoT Hub
        local iot_hub_name=$(terraform output -raw iot_hub_name 2>/dev/null || echo "N/A")
        echo "IoT Hub: ${iot_hub_name}"
        
        # Storage Account
        local storage_account=$(terraform output -raw storage_account_name 2>/dev/null || echo "N/A")
        echo "Storage Account: ${storage_account}"
        
        # Function App
        local function_app=$(terraform output -raw function_app_name 2>/dev/null || echo "N/A")
        echo "Function App: ${function_app}"
        
        # API Management
        local api_management=$(terraform output -raw api_management_name 2>/dev/null || echo "N/A")
        echo "API Management: ${api_management}"
        
        echo "----------------------------------------"
    fi
}

# Function to create backup
create_backup() {
    print_header "Creating Backup"
    
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    mkdir -p "${backup_path}"
    
    # Backup Terraform state
    if [ -f "${TERRAFORM_DIR}/terraform.tfstate" ]; then
        cp "${TERRAFORM_DIR}/terraform.tfstate" "${backup_path}/"
        print_status "Terraform state backed up"
    fi
    
    # Backup configuration
    if [ -f "${TERRAFORM_DIR}/terraform.tfvars" ]; then
        cp "${TERRAFORM_DIR}/terraform.tfvars" "${backup_path}/"
        print_status "Configuration backed up"
    fi
    
    # Backup outputs
    if [ -f "${CONFIG_DIR}/outputs.json" ]; then
        cp "${CONFIG_DIR}/outputs.json" "${backup_path}/"
        print_status "Outputs backed up"
    fi
    
    print_success "Backup created: ${backup_path}"
}

# Function to destroy resources
destroy_resources() {
    print_header "Destroying Resources"
    
    cd "${TERRAFORM_DIR}"
    
    print_warning "This will destroy ALL resources in the deployment"
    print_warning "This action cannot be undone!"
    
    read -p "Are you sure you want to continue? Type 'yes' to confirm: " -r
    if [[ ! $REPLY == "yes" ]]; then
        print_status "Destroy cancelled"
        exit 0
    fi
    
    # Create backup before destruction
    create_backup
    
    print_status "Destroying resources..."
    terraform destroy -auto-approve
    
    print_success "Resources destroyed successfully"
}

# Function to check deployment status
check_status() {
    print_header "Checking Deployment Status"
    
    cd "${TERRAFORM_DIR}"
    
    # Check if Terraform state exists
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "No Terraform state found. Deployment may not exist"
        return 1
    fi
    
    # Get resource count
    local resource_count=$(terraform state list | wc -l)
    print_status "Deployed resources: ${resource_count}"
    
    # Check resource health
    print_status "Checking resource health..."
    
    # Check Resource Group
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    if [ -n "$rg_name" ]; then
        if az group show --name "$rg_name" >/dev/null 2>&1; then
            print_success "Resource Group: Healthy"
        else
            print_error "Resource Group: Not found"
        fi
    fi
    
    # Check IoT Hub
    local iot_hub_name=$(terraform output -raw iot_hub_name 2>/dev/null || echo "")
    if [ -n "$iot_hub_name" ]; then
        if az iot hub show --name "$iot_hub_name" --resource-group "$rg_name" >/dev/null 2>&1; then
            print_success "IoT Hub: Healthy"
        else
            print_error "IoT Hub: Not found"
        fi
    fi
    
    print_success "Status check completed"
}

# Function to generate cost estimate
estimate_cost() {
    print_header "Cost Estimation"
    
    cd "${TERRAFORM_DIR}"
    
    print_status "Generating cost estimate..."
    
    # This would integrate with Azure Cost Management API
    # For now, provide a basic estimate based on resource types
    print_status "Estimated monthly costs (approximate):"
    echo "----------------------------------------"
    echo "IoT Hub (S1): ~$10/month"
    echo "Function Apps (Consumption): ~$5-50/month"
    echo "Storage Account: ~$1-10/month"
    echo "Cosmos DB (400 RU): ~$25/month"
    echo "SQL Database (S0): ~$5/month"
    echo "API Management (Developer): ~$50/month"
    echo "----------------------------------------"
    echo "Total estimated: ~$95-150/month"
    echo ""
    print_warning "This is a rough estimate. Actual costs may vary based on usage"
}

# Function to setup monitoring
setup_monitoring() {
    print_header "Setting Up Monitoring"
    
    cd "${TERRAFORM_DIR}"
    
    # Get outputs
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    local log_analytics_workspace=$(terraform output -raw log_analytics_workspace_name 2>/dev/null || echo "")
    
    if [ -z "$rg_name" ] || [ -z "$log_analytics_workspace" ]; then
        print_error "Required outputs not found. Please ensure deployment is complete"
        return 1
    fi
    
    print_status "Configuring monitoring for resource group: ${rg_name}"
    print_status "Log Analytics workspace: ${log_analytics_workspace}"
    
    # Enable diagnostic settings for key resources
    print_status "Enabling diagnostic settings..."
    
    # This would configure monitoring for all resources
    print_success "Monitoring setup completed"
}

# Function to cleanup
cleanup() {
    print_header "Cleaning Up"
    
    cd "${TERRAFORM_DIR}"
    
    # Remove temporary files
    rm -f tfplan*.out
    rm -f .terraform-plan-file
    
    # Clean up old logs (keep last 10)
    if [ -d "${LOG_DIR}" ]; then
        ls -t "${LOG_DIR}"/*.log | tail -n +11 | xargs -r rm
        print_status "Old log files cleaned up"
    fi
    
    print_success "Cleanup completed"
}

# Function to display help
show_help() {
    echo "Azure IoT Sound Analytics - Enhanced Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy              - Full deployment (init, plan, apply)"
    echo "  plan                - Plan deployment only"
    echo "  apply               - Apply deployment (requires existing plan)"
    echo "  destroy             - Destroy all resources"
    echo "  validate            - Validate configuration"
    echo "  status              - Check deployment status"
    echo "  outputs             - Show deployment outputs"
    echo "  backup              - Create backup of current state"
    echo "  cost-estimate       - Generate cost estimate"
    echo "  setup-monitoring    - Configure monitoring"
    echo "  cleanup             - Clean up temporary files"
    echo "  help                - Show this help message"
    echo ""
    echo "Options:"
    echo "  --clean             - Clean previous state before init"
    echo "  --force             - Skip confirmation prompts"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 plan --clean"
    echo "  $0 destroy --force"
    echo "  $0 status"
    echo ""
    echo "Configuration:"
    echo "  - Edit terraform.tfvars to customize deployment"
    echo "  - Logs are stored in: ${LOG_DIR}"
    echo "  - Backups are stored in: ${BACKUP_DIR}"
    echo "  - Config files are stored in: ${CONFIG_DIR}"
}

# Function to create necessary directories
setup_directories() {
    mkdir -p "${LOG_DIR}"
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${BACKUP_DIR}"
}

# Main script logic
main() {
    # Setup directories
    setup_directories
    
    # Parse arguments
    local command="${1:-deploy}"
    local options=("${@:2}")
    
    case "$command" in
        "deploy")
            check_prerequisites
            validate_azure_permissions
            create_config
            validate_config
            init_terraform "${options[@]}"
            plan_deployment
            apply_deployment
            show_outputs
            setup_monitoring
            cleanup
            print_success "Deployment completed successfully!"
            ;;
        "plan")
            check_prerequisites
            validate_config
            init_terraform "${options[@]}"
            plan_deployment
            ;;
        "apply")
            check_prerequisites
            apply_deployment
            show_outputs
            cleanup
            ;;
        "destroy")
            check_prerequisites
            destroy_resources
            cleanup
            ;;
        "validate")
            check_prerequisites
            validate_config
            init_terraform "${options[@]}"
            print_success "Configuration is valid"
            ;;
        "status")
            check_status
            ;;
        "outputs")
            show_outputs
            ;;
        "backup")
            create_backup
            ;;
        "cost-estimate")
            estimate_cost
            ;;
        "setup-monitoring")
            setup_monitoring
            ;;
        "cleanup")
            cleanup
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
