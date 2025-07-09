#!/bin/bash

# D&D Campaign Organizer - Azure Infrastructure Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="dnd-campaign-organizer-rg"
LOCATION="eastus"
AKS_CLUSTER_NAME="dnd-campaign-organizer-aks"
ACR_NAME="dndcampaignorganizeracr"
COSMOS_DB_NAME="dnd-campaign-organizer-cosmos"
STORAGE_ACCOUNT_NAME="dndcampaignorganizer"
KEY_VAULT_NAME="dnd-campaign-organizer-kv"
APP_INSIGHTS_NAME="dnd-campaign-organizer-insights"

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
    echo "  -l, --location LOCATION      Azure location [default: eastus]"
    echo "  -c, --cluster-name NAME      AKS cluster name [default: dnd-campaign-organizer-aks]"
    echo "  -r, --acr-name NAME          ACR name [default: dndcampaignorganizeracr]"
    echo "  -d, --cosmos-name NAME       Cosmos DB name [default: dnd-campaign-organizer-cosmos]"
    echo "  -s, --storage-name NAME      Storage account name [default: dndcampaignorganizer]"
    echo "  -k, --key-vault-name NAME    Key Vault name [default: dnd-campaign-organizer-kv]"
    echo "  -i, --insights-name NAME     App Insights name [default: dnd-campaign-organizer-insights]"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use default names"
    echo "  $0 -l westus2                        # Use West US 2 location"
    echo "  $0 -g my-rg -c my-cluster            # Custom resource group and cluster"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -c|--cluster-name)
            AKS_CLUSTER_NAME="$2"
            shift 2
            ;;
        -r|--acr-name)
            ACR_NAME="$2"
            shift 2
            ;;
        -d|--cosmos-name)
            COSMOS_DB_NAME="$2"
            shift 2
            ;;
        -s|--storage-name)
            STORAGE_ACCOUNT_NAME="$2"
            shift 2
            ;;
        -k|--key-vault-name)
            KEY_VAULT_NAME="$2"
            shift 2
            ;;
        -i|--insights-name)
            APP_INSIGHTS_NAME="$2"
            shift 2
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
    print_error "Azure CLI is not installed. Please install it first:"
    echo "  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    print_error "You are not logged in to Azure. Please run:"
    echo "  az login"
    exit 1
fi

print_status "Setting up Azure resources for D&D Campaign Organizer..."
print_status "Resource Group: $RESOURCE_GROUP"
print_status "Location: $LOCATION"
print_status "AKS Cluster: $AKS_CLUSTER_NAME"
print_status "ACR: $ACR_NAME"
print_status "Cosmos DB: $COSMOS_DB_NAME"
print_status "Storage Account: $STORAGE_ACCOUNT_NAME"
print_status "Key Vault: $KEY_VAULT_NAME"
print_status "App Insights: $APP_INSIGHTS_NAME"

# Create resource group
print_status "Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
print_success "Resource group created"

# Create Azure Container Registry
print_status "Creating Azure Container Registry..."
az acr create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACR_NAME" \
    --sku Basic \
    --admin-enabled true

ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query "loginServer" --output tsv)
print_success "ACR created: $ACR_LOGIN_SERVER"

# Create Cosmos DB account
print_status "Creating Cosmos DB account..."
az cosmosdb create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$COSMOS_DB_NAME" \
    --kind GlobalDocumentDB \
    --capabilities EnableServerless

# Create Cosmos DB database
print_status "Creating Cosmos DB database..."
az cosmosdb sql database create \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$COSMOS_DB_NAME" \
    --name "dnd-campaign-organizer"

# Create Cosmos DB container
print_status "Creating Cosmos DB container..."
az cosmosdb sql container create \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$COSMOS_DB_NAME" \
    --database-name "dnd-campaign-organizer" \
    --name "campaigns" \
    --partition-key-path "/id"

COSMOS_ENDPOINT=$(az cosmosdb show --name "$COSMOS_DB_NAME" --resource-group "$RESOURCE_GROUP" --query "documentEndpoint" --output tsv)
COSMOS_KEY=$(az cosmosdb keys list --name "$COSMOS_DB_NAME" --resource-group "$RESOURCE_GROUP" --query "primaryMasterKey" --output tsv)
print_success "Cosmos DB created: $COSMOS_ENDPOINT"

# Create Storage Account
print_status "Creating Storage Account..."
az storage account create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$STORAGE_ACCOUNT_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2

# Create blob container
print_status "Creating blob container..."
az storage container create \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --name "campaign-assets" \
    --public-access off

STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --query "connectionString" --output tsv)
print_success "Storage account created"

# Create Key Vault
print_status "Creating Key Vault..."
az keyvault create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$KEY_VAULT_NAME" \
    --location "$LOCATION" \
    --sku standard \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true

# Store secrets in Key Vault
print_status "Storing secrets in Key Vault..."
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "cosmos-connection-string" --value "$COSMOS_ENDPOINT"
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "cosmos-key" --value "$COSMOS_KEY"
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "storage-connection-string" --value "$STORAGE_CONNECTION_STRING"
print_success "Secrets stored in Key Vault"

# Create Application Insights
print_status "Creating Application Insights..."
az monitor app-insights component create \
    --resource-group "$RESOURCE_GROUP" \
    --app "$APP_INSIGHTS_NAME" \
    --location "$LOCATION" \
    --kind web

APP_INSIGHTS_KEY=$(az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$RESOURCE_GROUP" --query "InstrumentationKey" --output tsv)
print_success "Application Insights created"

# Create AKS cluster
print_status "Creating AKS cluster..."
az aks create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME" \
    --node-count 2 \
    --node-vm-size Standard_B2s \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --attach-acr "$ACR_NAME"

# Get AKS credentials
print_status "Getting AKS credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --overwrite-existing

# Install NGINX Ingress Controller
print_status "Installing NGINX Ingress Controller..."
kubectl create namespace ingress-basic
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace ingress-basic \
    --set controller.replicaCount=1 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux

# Install cert-manager for SSL certificates
print_status "Installing cert-manager..."
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --set installCRDs=true

# Create ClusterIssuer for Let's Encrypt
print_status "Creating ClusterIssuer for SSL certificates..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

print_success "AKS cluster created and configured"

# Create image pull secret for ACR
print_status "Creating image pull secret..."
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" --output tsv)

kubectl create secret docker-registry acr-secret \
    --docker-server="$ACR_LOGIN_SERVER" \
    --docker-username="$ACR_USERNAME" \
    --docker-password="$ACR_PASSWORD" \
    --namespace="dnd-campaign-organizer" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry acr-secret \
    --docker-server="$ACR_LOGIN_SERVER" \
    --docker-username="$ACR_USERNAME" \
    --docker-password="$ACR_PASSWORD" \
    --namespace="dnd-campaign-organizer-dev" \
    --dry-run=client -o yaml | kubectl apply -f -

print_success "Image pull secret created"

# Output configuration
print_success "Azure infrastructure setup complete!"
echo ""
echo "📋 Configuration Summary:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  AKS Cluster: $AKS_CLUSTER_NAME"
echo "  ACR: $ACR_LOGIN_SERVER"
echo "  Cosmos DB: $COSMOS_ENDPOINT"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Key Vault: $KEY_VAULT_NAME"
echo "  App Insights: $APP_INSIGHTS_NAME"
echo ""
echo "🔧 Next Steps:"
echo "  1. Update k8s/base/secret.yaml with real values"
echo "  2. Build and push Docker images to ACR"
echo "  3. Deploy to Kubernetes using: ./k8s/deploy.sh"
echo "  4. Configure your domain and update ingress"
echo ""
echo "📚 Documentation:"
echo "  - Kubernetes manifests: ./k8s/README.md"
echo "  - Docker setup: ./DOCKER.md"
echo "  - Azure resources: ./infra/README.md" 