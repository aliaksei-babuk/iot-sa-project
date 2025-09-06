#!/bin/bash

# Azure IoT Sound Analytics - Deployment Script
# This script automates the deployment of the Terraform infrastructure

set -e

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install Azure CLI"
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show >/dev/null 2>&1; then
        print_error "Not logged in to Azure. Please run 'az login'"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to validate configuration
validate_config() {
    print_status "Validating configuration..."
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_warning "Please edit terraform.tfvars with your configuration before proceeding"
            exit 1
        else
            print_error "terraform.tfvars.example not found. Please create terraform.tfvars"
            exit 1
        fi
    fi
    
    print_success "Configuration validation passed"
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized"
}

# Function to plan deployment
plan_deployment() {
    print_status "Planning deployment..."
    terraform plan -out=tfplan
    print_success "Deployment plan created"
}

# Function to apply deployment
apply_deployment() {
    print_status "Applying deployment..."
    terraform apply tfplan
    print_success "Deployment completed"
}

# Function to show outputs
show_outputs() {
    print_status "Deployment outputs:"
    terraform output
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f tfplan
    print_success "Cleanup completed"
}

# Function to display help
show_help() {
    echo "Azure IoT Sound Analytics - Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy    - Full deployment (init, plan, apply)"
    echo "  plan      - Plan deployment only"
    echo "  apply     - Apply deployment (requires existing plan)"
    echo "  destroy   - Destroy all resources"
    echo "  validate  - Validate configuration"
    echo "  outputs   - Show deployment outputs"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 plan"
    echo "  $0 destroy"
}

# Main script logic
main() {
    case "${1:-deploy}" in
        "deploy")
            check_prerequisites
            validate_config
            init_terraform
            plan_deployment
            apply_deployment
            show_outputs
            cleanup
            ;;
        "plan")
            check_prerequisites
            validate_config
            init_terraform
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
            print_warning "This will destroy all resources. Are you sure? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                terraform destroy
                print_success "Resources destroyed"
            else
                print_status "Destroy cancelled"
            fi
            ;;
        "validate")
            check_prerequisites
            validate_config
            init_terraform
            terraform validate
            print_success "Configuration is valid"
            ;;
        "outputs")
            terraform output
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
