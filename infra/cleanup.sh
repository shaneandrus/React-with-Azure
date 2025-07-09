#!/bin/bash

# D&D Campaign Organizer - Azure Cleanup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="dnd-campaign-organizer-rg"
CONFIRM=false

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -g, --resource-group NAME    Resource group name [default: dnd-campaign-organizer-rg]"
    echo "  -y, --yes                    Skip confirmation prompt"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Cleanup with confirmation"
    echo "  $0 -y                               # Cleanup without confirmation"
    echo "  $0 -g my-custom-rg                  # Cleanup specific resource group"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -y|--yes)
            CONFIRM=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    print_error "You are not logged in to Azure. Please run:"
    echo "  az login"
    exit 1
fi

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_error "Resource group '$RESOURCE_GROUP' does not exist."
    exit 1
fi

print_warning "This will delete ALL resources in the resource group: $RESOURCE_GROUP"
print_warning "This action cannot be undone!"

# List resources that will be deleted
print_status "Resources that will be deleted:"
az resource list --resource-group "$RESOURCE_GROUP" --output table

if [ "$CONFIRM" = false ]; then
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Cleanup cancelled."
        exit 0
    fi
fi

print_status "Starting cleanup of Azure resources..."

# Delete resource group (this will delete all resources in the group)
print_status "Deleting resource group '$RESOURCE_GROUP'..."
az group delete --name "$RESOURCE_GROUP" --yes --no-wait

print_success "Cleanup initiated! Resource group deletion is in progress."
echo ""
echo "📋 Note:"
echo "  - Resource group deletion may take several minutes"
echo "  - You can check status with: az group show --name $RESOURCE_GROUP"
echo "  - All resources in the group will be deleted"
echo ""
echo "🔧 To recreate resources:"
echo "  ./infra/azure-setup.sh" 