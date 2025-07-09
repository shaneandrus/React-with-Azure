# Azure Infrastructure for D&D Campaign Organizer

This directory contains Infrastructure as Code (IaC) scripts and documentation for setting up Azure resources for the D&D Campaign Organizer project.

## 🏗️ **Azure Resources Overview**

### **Core Infrastructure**
- **Azure Kubernetes Service (AKS)** - Container orchestration
- **Azure Container Registry (ACR)** - Docker image storage
- **Azure Cosmos DB** - NoSQL database for campaign data
- **Azure Storage Account** - Blob storage for assets
- **Azure Key Vault** - Secrets management
- **Azure Application Insights** - Monitoring and logging

### **Network & Security**
- **Virtual Network** - Network isolation
- **Load Balancer** - Traffic distribution
- **Network Security Groups** - Firewall rules
- **SSL/TLS Certificates** - Secure communication

## 🚀 **Quick Setup**

### **Prerequisites**
1. **Azure CLI** installed and configured
2. **kubectl** installed
3. **helm** installed (for ingress and cert-manager)
4. **Azure subscription** with sufficient permissions

### **One-Command Setup**
```bash
# Run the automated setup script
./infra/azure-setup.sh

# Or with custom parameters
./infra/azure-setup.sh -l westus2 -g my-custom-rg
```

### **Manual Setup Steps**
If you prefer to set up resources manually:

1. **Create Resource Group**
   ```bash
   az group create --name dnd-campaign-organizer-rg --location eastus
   ```

2. **Create AKS Cluster**
   ```bash
   az aks create \
     --resource-group dnd-campaign-organizer-rg \
     --name dnd-campaign-organizer-aks \
     --node-count 2 \
     --node-vm-size Standard_B2s \
     --enable-addons monitoring \
     --generate-ssh-keys
   ```

3. **Create Azure Container Registry**
   ```bash
   az acr create \
     --resource-group dnd-campaign-organizer-rg \
     --name dndcampaignorganizeracr \
     --sku Basic \
     --admin-enabled true
   ```

4. **Create Cosmos DB**
   ```bash
   az cosmosdb create \
     --resource-group dnd-campaign-organizer-rg \
     --name dnd-campaign-organizer-cosmos \
     --kind GlobalDocumentDB \
     --capabilities EnableServerless
   ```

## 📋 **Resource Details**

### **AKS Cluster**
- **Node Count**: 2 nodes (scalable)
- **VM Size**: Standard_B2s (cost-effective)
- **Monitoring**: Azure Monitor enabled
- **Add-ons**: NGINX Ingress, cert-manager

### **Azure Container Registry**
- **SKU**: Basic (cost-effective for development)
- **Admin Access**: Enabled for simplicity
- **Geographic Replication**: Not enabled (Basic SKU)

### **Cosmos DB**
- **API**: SQL (Core)
- **Capacity Mode**: Serverless (pay-per-use)
- **Database**: dnd-campaign-organizer
- **Container**: campaigns

### **Storage Account**
- **SKU**: Standard_LRS
- **Container**: campaign-assets
- **Access**: Private (no public access)

### **Key Vault**
- **SKU**: Standard
- **Access**: Managed Identity (recommended)
- **Secrets**: Database connections, API keys

## 🔧 **Configuration**

### **Environment Variables**
After setup, update your Kubernetes secrets:

```bash
# Get Cosmos DB connection string
COSMOS_ENDPOINT=$(az cosmosdb show --name dnd-campaign-organizer-cosmos --resource-group dnd-campaign-organizer-rg --query "documentEndpoint" --output tsv)
COSMOS_KEY=$(az cosmosdb keys list --name dnd-campaign-organizer-cosmos --resource-group dnd-campaign-organizer-rg --query "primaryMasterKey" --output tsv)

# Get Storage connection string
STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name dndcampaignorganizer --resource-group dnd-campaign-organizer-rg --query "connectionString" --output tsv)

# Update Kubernetes secrets
kubectl create secret generic dnd-app-secrets \
  --from-literal=DATABASE_URL="$COSMOS_ENDPOINT" \
  --from-literal=AZURE_STORAGE_CONNECTION_STRING="$STORAGE_CONNECTION_STRING" \
  --namespace=dnd-campaign-organizer
```

### **Image Pull Secrets**
```bash
# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name dndcampaignorganizeracr --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name dndcampaignorganizeracr --query "passwords[0].value" --output tsv)

# Create image pull secret
kubectl create secret docker-registry acr-secret \
  --docker-server=dndcampaignorganizeracr.azurecr.io \
  --docker-username="$ACR_USERNAME" \
  --docker-password="$ACR_PASSWORD" \
  --namespace=dnd-campaign-organizer
```

## 🚀 **Deployment**

### **Build and Push Images**
```bash
# Build images
docker-compose build

# Tag for ACR
docker tag dnd-campaign-organizer-frontend:latest dndcampaignorganizeracr.azurecr.io/frontend:latest
docker tag dnd-campaign-organizer-api:latest dndcampaignorganizeracr.azurecr.io/api:latest
docker tag dnd-campaign-organizer-discord-bot:latest dndcampaignorganizeracr.azurecr.io/discord-bot:latest

# Push to ACR
az acr login --name dndcampaignorganizeracr
docker push dndcampaignorganizeracr.azurecr.io/frontend:latest
docker push dndcampaignorganizeracr.azurecr.io/api:latest
docker push dndcampaignorganizeracr.azurecr.io/discord-bot:latest
```

### **Deploy to Kubernetes**
```bash
# Deploy to development
./k8s/deploy.sh -e development

# Deploy to production
./k8s/deploy.sh -e production
```

## 📊 **Monitoring**

### **Application Insights**
- **Metrics**: Request rates, response times, errors
- **Logs**: Application logs, traces
- **Alerts**: Custom alert rules
- **Dashboards**: Custom monitoring dashboards

### **AKS Monitoring**
- **Node Metrics**: CPU, memory, disk usage
- **Pod Metrics**: Resource consumption
- **Network**: Ingress/egress traffic
- **Logs**: Container logs, system logs

## 🔒 **Security**

### **Network Security**
- **Private AKS**: Nodes in private subnet
- **ACR Firewall**: Restrict access to ACR
- **Cosmos DB**: Private endpoints (optional)
- **Key Vault**: Private endpoints (optional)

### **Identity & Access**
- **Managed Identities**: For AKS and applications
- **RBAC**: Kubernetes role-based access
- **Azure AD**: Integration for authentication
- **Service Principals**: For CI/CD pipelines

### **Data Protection**
- **Encryption at Rest**: All data encrypted
- **Encryption in Transit**: TLS 1.2+ required
- **Backup**: Automated backups for Cosmos DB
- **Compliance**: SOC, ISO, HIPAA (depending on tier)

## 💰 **Cost Optimization**

### **Development Environment**
- **AKS**: 2 nodes, Standard_B2s
- **ACR**: Basic SKU
- **Cosmos DB**: Serverless
- **Storage**: Standard_LRS
- **Estimated Cost**: ~$100-200/month

### **Production Environment**
- **AKS**: 3+ nodes, Standard_D2s
- **ACR**: Standard SKU
- **Cosmos DB**: Provisioned throughput
- **Storage**: Premium_LRS
- **Estimated Cost**: ~$300-500/month

### **Cost Reduction Tips**
1. **Use Spot Instances** for non-critical workloads
2. **Right-size VMs** based on actual usage
3. **Enable auto-scaling** for AKS
4. **Use reserved instances** for predictable workloads
5. **Monitor and optimize** resource usage

## 🛠️ **Troubleshooting**

### **Common Issues**

1. **AKS Node Pool Issues**
   ```bash
   # Check node status
   kubectl get nodes
   
   # Check node events
   kubectl describe node <node-name>
   ```

2. **ACR Authentication Issues**
   ```bash
   # Re-authenticate with ACR
   az acr login --name dndcampaignorganizeracr
   
   # Check ACR credentials
   az acr credential show --name dndcampaignorganizeracr
   ```

3. **Cosmos DB Connection Issues**
   ```bash
   # Test connection
   az cosmosdb keys list --name dnd-campaign-organizer-cosmos --resource-group dnd-campaign-organizer-rg
   ```

4. **Storage Account Issues**
   ```bash
   # Check storage account status
   az storage account show --name dndcampaignorganizer --resource-group dnd-campaign-organizer-rg
   ```

### **Debug Commands**
```bash
# Check AKS cluster status
az aks show --name dnd-campaign-organizer-aks --resource-group dnd-campaign-organizer-rg

# Get AKS credentials
az aks get-credentials --name dnd-campaign-organizer-aks --resource-group dnd-campaign-organizer-rg

# Check resource group resources
az resource list --resource-group dnd-campaign-organizer-rg --output table
```

## 🚀 **Next Steps**

1. **Set up CI/CD Pipeline**
   - GitHub Actions or Azure DevOps
   - Automated testing
   - Automated deployment

2. **Configure Monitoring**
   - Set up alerting rules
   - Create custom dashboards
   - Configure log analytics

3. **Security Hardening**
   - Enable private endpoints
   - Configure network policies
   - Set up Azure AD integration

4. **Performance Optimization**
   - Enable auto-scaling
   - Optimize resource allocation
   - Implement caching strategies

## 📚 **Additional Resources**

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure Cosmos DB Documentation](https://docs.microsoft.com/en-us/azure/cosmos-db/)
- [Azure Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Azure Application Insights Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
