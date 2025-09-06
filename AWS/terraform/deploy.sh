#!/bin/bash

# AWS IoT Sound Analytics - Deployment Script
# This script automates the deployment of the Terraform infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI"
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure'"
        exit 1
    fi
    
    # Check Terraform version
    terraform_version=$(terraform version -json | jq -r '.terraform_version')
    required_version="1.0.0"
    if [ "$(printf '%s\n' "$required_version" "$terraform_version" | sort -V | head -n1)" != "$required_version" ]; then
        print_error "Terraform version $terraform_version is not supported. Please install Terraform >= $required_version"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_status "Terraform initialized successfully"
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    terraform validate
    print_status "Terraform configuration is valid"
}

# Function to plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_status "Terraform plan created successfully"
}

# Function to apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    print_status "Terraform deployment completed successfully"
}

# Function to show outputs
show_outputs() {
    print_status "Infrastructure outputs:"
    terraform output
}

# Function to create terraform.tfvars if it doesn't exist
create_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your specific values before running the deployment"
        exit 1
    fi
}

# Function to check if we're in the right directory
check_directory() {
    if [ ! -f "main.tf" ]; then
        print_error "main.tf not found. Please run this script from the terraform directory"
        exit 1
    fi
}

# Function to display help
show_help() {
    echo "AWS IoT Sound Analytics - Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -i, --init     Only initialize Terraform"
    echo "  -v, --validate Only validate Terraform configuration"
    echo "  -p, --plan     Only create Terraform plan"
    echo "  -a, --apply    Apply Terraform deployment"
    echo "  -o, --output   Show Terraform outputs"
    echo "  -c, --cleanup  Destroy all resources"
    echo "  -f, --force    Skip confirmation prompts"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full deployment with confirmation"
    echo "  $0 --plan            # Only create plan"
    echo "  $0 --apply --force   # Apply without confirmation"
    echo "  $0 --cleanup         # Destroy all resources"
}

# Function to cleanup resources
cleanup_terraform() {
    print_warning "This will destroy all resources. Are you sure? (y/N)"
    if [ "$FORCE" = "true" ]; then
        response="y"
    else
        read -r response
    fi
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "Destroying Terraform resources..."
        terraform destroy -auto-approve
        print_status "Cleanup completed successfully"
    else
        print_status "Cleanup cancelled"
    fi
}

# Main function
main() {
    # Parse command line arguments
    FORCE="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--init)
                check_directory
                check_prerequisites
                init_terraform
                exit 0
                ;;
            -v|--validate)
                check_directory
                check_prerequisites
                init_terraform
                validate_terraform
                exit 0
                ;;
            -p|--plan)
                check_directory
                check_prerequisites
                create_tfvars
                init_terraform
                validate_terraform
                plan_terraform
                exit 0
                ;;
            -a|--apply)
                check_directory
                check_prerequisites
                create_tfvars
                init_terraform
                validate_terraform
                plan_terraform
                apply_terraform
                show_outputs
                exit 0
                ;;
            -o|--output)
                check_directory
                show_outputs
                exit 0
                ;;
            -c|--cleanup)
                check_directory
                check_prerequisites
                cleanup_terraform
                exit 0
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default: full deployment
    check_directory
    check_prerequisites
    create_tfvars
    init_terraform
    validate_terraform
    plan_terraform
    
    if [ "$FORCE" = "true" ]; then
        apply_terraform
    else
        print_warning "Do you want to apply the changes? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            apply_terraform
        else
            print_status "Deployment cancelled"
            exit 0
        fi
    fi
    
    show_outputs
}

# Run main function with all arguments
main "$@"
