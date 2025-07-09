#!/bin/bash

# D&D Campaign Organizer - Build and Push to ACR Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="dnd-campaign-organizer-rg"
ACR_NAME="dndcampaignorganizeracr"
TAG="latest"
PUSH=true
BUILD=true

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
    echo "  -r, --acr-name NAME          ACR name [default: dndcampaignorganizeracr]"
    echo "  -t, --tag TAG                Image tag [default: latest]"
    echo "  -b, --build-only             Build only, don't push"
    echo "  -p, --push-only              Push only, don't build"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Build and push with latest tag"
    echo "  $0 -t v1.0.0                        # Build and push with v1.0.0 tag"
    echo "  $0 -b                               # Build only"
    echo "  $0 -p                               # Push only"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -r|--acr-name)
            ACR_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -b|--build-only)
            PUSH=false
            shift
            ;;
        -p|--push-only)
            BUILD=false
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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
    print_error "You are not logged in to Azure. Please run:"
    echo "  az login"
    exit 1
fi

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query "loginServer" --output tsv 2>/dev/null || echo "")

if [ -z "$ACR_LOGIN_SERVER" ]; then
    print_error "ACR '$ACR_NAME' not found in resource group '$RESOURCE_GROUP'"
    echo "Please run the Azure setup script first: ./infra/azure-setup.sh"
    exit 1
fi

print_status "Building and pushing Docker images to ACR..."
print_status "Resource Group: $RESOURCE_GROUP"
print_status "ACR: $ACR_LOGIN_SERVER"
print_status "Tag: $TAG"
print_status "Build: $BUILD"
print_status "Push: $PUSH"

# Login to ACR
print_status "Logging in to Azure Container Registry..."
az acr login --name "$ACR_NAME"
print_success "Logged in to ACR"

# Build images if requested
if [ "$BUILD" = true ]; then
    print_status "Building Docker images..."
    
    # Build frontend
    print_status "Building frontend image..."
    docker build -f apps/frontend/Dockerfile -t "dnd-campaign-organizer-frontend:$TAG" .
    docker tag "dnd-campaign-organizer-frontend:$TAG" "$ACR_LOGIN_SERVER/frontend:$TAG"
    print_success "Frontend image built"
    
    # Build API
    print_status "Building API image..."
    docker build -f apps/api/Dockerfile -t "dnd-campaign-organizer-api:$TAG" .
    docker tag "dnd-campaign-organizer-api:$TAG" "$ACR_LOGIN_SERVER/api:$TAG"
    print_success "API image built"
    
    # Build Discord Bot
    print_status "Building Discord Bot image..."
    docker build -f apps/discord-bot/Dockerfile -t "dnd-campaign-organizer-discord-bot:$TAG" .
    docker tag "dnd-campaign-organizer-discord-bot:$TAG" "$ACR_LOGIN_SERVER/discord-bot:$TAG"
    print_success "Discord Bot image built"
    
    print_success "All images built successfully"
else
    print_status "Skipping build step"
fi

# Push images if requested
if [ "$PUSH" = true ]; then
    print_status "Pushing Docker images to ACR..."
    
    # Push frontend
    print_status "Pushing frontend image..."
    docker push "$ACR_LOGIN_SERVER/frontend:$TAG"
    print_success "Frontend image pushed"
    
    # Push API
    print_status "Pushing API image..."
    docker push "$ACR_LOGIN_SERVER/api:$TAG"
    print_success "API image pushed"
    
    # Push Discord Bot
    print_status "Pushing Discord Bot image..."
    docker push "$ACR_LOGIN_SERVER/discord-bot:$TAG"
    print_success "Discord Bot image pushed"
    
    print_success "All images pushed successfully"
else
    print_status "Skipping push step"
fi

# Show image information
print_status "Image information:"
echo "  Frontend: $ACR_LOGIN_SERVER/frontend:$TAG"
echo "  API: $ACR_LOGIN_SERVER/api:$TAG"
echo "  Discord Bot: $ACR_LOGIN_SERVER/discord-bot:$TAG"

# Update Kubernetes manifests if pushing
if [ "$PUSH" = true ]; then
    print_status "Updating Kubernetes manifests..."
    
    # Update kustomization files with new image tags
    if [ "$TAG" != "latest" ]; then
        print_status "Updating image tags in Kubernetes manifests..."
        
        # Update development overlay
        sed -i.bak "s/newTag: dev/newTag: $TAG/g" k8s/overlays/development/kustomization.yaml
        sed -i.bak "s/newTag: v1.0.0/newTag: $TAG/g" k8s/overlays/production/kustomization.yaml
        
        print_success "Kubernetes manifests updated with tag: $TAG"
    fi
fi

print_success "Build and push process completed!"
echo ""
echo "📋 Next Steps:"
echo "  1. Deploy to Kubernetes: ./k8s/deploy.sh -e development"
echo "  2. Check deployment status: kubectl get pods -n dnd-campaign-organizer-dev"
echo "  3. View logs: kubectl logs -l app=api -n dnd-campaign-organizer-dev"
echo ""
echo "🔧 Useful Commands:"
echo "  # List images in ACR"
echo "  az acr repository list --name $ACR_NAME"
echo ""
echo "  # View image tags"
echo "  az acr repository show-tags --name $ACR_NAME --repository frontend"
echo ""
echo "  # Deploy to production"
echo "  ./k8s/deploy.sh -e production" 