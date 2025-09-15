#!/bin/bash

# Azure IoT Sound Analytics - Script Validation
# This script validates all deployment scripts for syntax and dependencies

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

# Function to check script syntax
check_syntax() {
    local script="$1"
    print_status "Checking syntax: $script"
    
    if bash -n "$script" 2>/dev/null; then
        print_success "Syntax OK: $script"
        return 0
    else
        print_error "Syntax error in: $script"
        return 1
    fi
}

# Function to check script dependencies
check_dependencies() {
    local script="$1"
    print_status "Checking dependencies: $script"
    
    local missing_deps=()
    
    # Check for required commands
    if grep -q "az " "$script" && ! command -v az >/dev/null 2>&1; then
        missing_deps+=("azure-cli")
    fi
    
    if grep -q "terraform " "$script" && ! command -v terraform >/dev/null 2>&1; then
        missing_deps+=("terraform")
    fi
    
    if grep -q "jq " "$script" && ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if grep -q "curl " "$script" && ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_warning "Missing dependencies for $script: ${missing_deps[*]}"
        return 1
    else
        print_success "Dependencies OK: $script"
        return 0
    fi
}

# Function to check file permissions
check_permissions() {
    local script="$1"
    print_status "Checking permissions: $script"
    
    if [ -x "$script" ]; then
        print_success "Executable: $script"
        return 0
    else
        print_warning "Not executable: $script"
        return 1
    fi
}

# Function to validate all scripts
validate_all() {
    print_status "Validating all deployment scripts..."
    
    local scripts=(
        "deploy-azure.sh"
        "config-manager.sh"
        "azure-deploy"
        "validate-scripts.sh"
    )
    
    local errors=0
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            echo "----------------------------------------"
            echo "Validating: $script"
            echo "----------------------------------------"
            
            # Check syntax
            if ! check_syntax "$script"; then
                ((errors++))
            fi
            
            # Check dependencies
            if ! check_dependencies "$script"; then
                ((errors++))
            fi
            
            # Check permissions
            if ! check_permissions "$script"; then
                ((errors++))
            fi
            
            echo ""
        else
            print_error "Script not found: $script"
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        print_success "All scripts validated successfully!"
        return 0
    else
        print_error "Validation completed with $errors errors"
        return 1
    fi
}

# Function to fix permissions
fix_permissions() {
    print_status "Fixing script permissions..."
    
    local scripts=(
        "deploy-azure.sh"
        "config-manager.sh"
        "azure-deploy"
        "validate-scripts.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            print_success "Made executable: $script"
        fi
    done
}

# Function to show help
show_help() {
    echo "Azure IoT Sound Analytics - Script Validation"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  validate    - Validate all scripts (default)"
    echo "  fix-perms   - Fix script permissions"
    echo "  check <file> - Check specific script"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 validate"
    echo "  $0 fix-perms"
    echo "  $0 check deploy-azure.sh"
}

# Function to check specific script
check_script() {
    local script="$1"
    
    if [ ! -f "$script" ]; then
        print_error "Script not found: $script"
        exit 1
    fi
    
    echo "----------------------------------------"
    echo "Validating: $script"
    echo "----------------------------------------"
    
    local errors=0
    
    # Check syntax
    if ! check_syntax "$script"; then
        ((errors++))
    fi
    
    # Check dependencies
    if ! check_dependencies "$script"; then
        ((errors++))
    fi
    
    # Check permissions
    if ! check_permissions "$script"; then
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "Script validation passed!"
    else
        print_error "Script validation failed with $errors errors"
        exit 1
    fi
}

# Main script logic
main() {
    case "${1:-validate}" in
        "validate")
            validate_all
            ;;
        "fix-perms")
            fix_permissions
            ;;
        "check")
            if [ -z "$2" ]; then
                print_error "Script name required"
                show_help
                exit 1
            fi
            check_script "$2"
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
