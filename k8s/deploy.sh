#!/bin/bash

# D&D Campaign Organizer Kubernetes Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="development"
NAMESPACE="dnd-campaign-organizer-dev"
DRY_RUN=false

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
    echo "  -e, --environment ENV    Environment to deploy (development|production) [default: development]"
    echo "  -n, --namespace NAME     Kubernetes namespace [default: based on environment]"
    echo "  -d, --dry-run           Show what would be deployed without actually deploying"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy to development"
    echo "  $0 -e production                      # Deploy to production"
    echo "  $0 -e development -d                 # Dry run for development"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
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

# Validate environment
if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "production" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be 'development' or 'production'"
    exit 1
fi

# Set namespace based on environment if not specified
if [[ "$NAMESPACE" == "dnd-campaign-organizer-dev" && "$ENVIRONMENT" == "production" ]]; then
    NAMESPACE="dnd-campaign-organizer"
fi

print_status "Deploying D&D Campaign Organizer to $ENVIRONMENT environment"
print_status "Namespace: $NAMESPACE"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if kustomize is installed
if ! command -v kustomize &> /dev/null; then
    print_warning "kustomize is not installed. Installing via curl..."
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    sudo mv kustomize /usr/local/bin/
fi

# Check cluster connectivity
print_status "Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_success "Connected to cluster: $(kubectl config current-context)"

# Create namespace if it doesn't exist
print_status "Creating namespace if it doesn't exist..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy secrets (you'll need to update these with real values)
print_status "Deploying secrets..."
if [[ "$DRY_RUN" == "true" ]]; then
    kubectl apply -k "overlays/$ENVIRONMENT" --dry-run=client
else
    kubectl apply -k "overlays/$ENVIRONMENT"
fi

# Wait for deployments to be ready
if [[ "$DRY_RUN" == "false" ]]; then
    print_status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/frontend -n "$NAMESPACE"
    kubectl wait --for=condition=available --timeout=300s deployment/api -n "$NAMESPACE"
    kubectl wait --for=condition=available --timeout=300s deployment/discord-bot -n "$NAMESPACE"
    
    print_success "All deployments are ready!"
    
    # Show service status
    print_status "Service status:"
    kubectl get services -n "$NAMESPACE"
    
    print_status "Pod status:"
    kubectl get pods -n "$NAMESPACE"
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        print_status "Ingress status:"
        kubectl get ingress -n "$NAMESPACE"
    fi
else
    print_status "Dry run completed. No changes were made."
fi

print_success "Deployment completed successfully!" 