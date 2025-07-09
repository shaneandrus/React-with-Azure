# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying the D&D Campaign Organizer to Azure Kubernetes Service (AKS).

## 📁 Directory Structure

```
k8s/
├── base/                    # Base manifests for all environments
│   ├── namespace.yaml      # Namespace definition
│   ├── configmap.yaml      # Application configuration
│   ├── secret.yaml         # Sensitive data (templates)
│   ├── ingress.yaml        # Ingress configuration
│   ├── frontend/           # Frontend service manifests
│   ├── api/                # API service manifests
│   └── discord-bot/        # Discord bot manifests
├── overlays/               # Environment-specific configurations
│   ├── development/        # Development environment
│   └── production/         # Production environment
├── deploy.sh              # Deployment script
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and configured
2. **kubectl** installed and configured for your AKS cluster
3. **kustomize** installed (script will install if missing)
4. **Docker images** built and pushed to Azure Container Registry

### Deploy to Development

```bash
# Deploy to development environment
./k8s/deploy.sh -e development

# Dry run to see what would be deployed
./k8s/deploy.sh -e development -d
```

### Deploy to Production

```bash
# Deploy to production environment
./k8s/deploy.sh -e production

# Dry run for production
./k8s/deploy.sh -e production -d
```

## 🔧 Configuration

### Environment Variables

The application uses ConfigMaps and Secrets for configuration:

#### ConfigMap (dnd-app-config)
- `NODE_ENV`: Environment (development/production)
- `PORT`: API server port
- `REACT_APP_API_URL`: Frontend API URL
- `REACT_APP_GRAPHQL_URL`: GraphQL endpoint
- `DISCORD_BOT_PREFIX`: Discord bot command prefix
- `LOG_LEVEL`: Logging level
- `APP_NAME`: Application name
- `APP_VERSION`: Application version

#### Secret (dnd-app-secrets)
- `DISCORD_TOKEN`: Discord bot token
- `DATABASE_URL`: Database connection string
- `JWT_SECRET`: JWT signing secret
- `AZURE_STORAGE_CONNECTION_STRING`: Azure Storage connection

### Update Secrets

Before deploying, update the secrets in `k8s/base/secret.yaml`:

```bash
# Encode your Discord token
echo -n "your_discord_token_here" | base64

# Encode your database URL
echo -n "your_database_connection_string" | base64

# Encode your JWT secret
echo -n "your_jwt_secret_here" | base64

# Encode your Azure Storage connection string
echo -n "your_azure_storage_connection_string" | base64
```

Replace the placeholder values in `k8s/base/secret.yaml` with your encoded values.

## 🏗️ Architecture

### Services

1. **Frontend Service**
   - React application
   - Served via nginx
   - Port: 5173
   - Replicas: 2 (production), 1 (development)

2. **API Service**
   - Node.js/GraphQL API
   - Port: 4000
   - Replicas: 3 (production), 1 (development)

3. **Discord Bot Service**
   - Discord bot application
   - No external port (internal only)
   - Replicas: 1

### Networking

- **Internal Communication**: Services communicate via Kubernetes service names
- **External Access**: Ingress controller routes external traffic
- **SSL/TLS**: Automatic certificate management via cert-manager

## 🔒 Security

### Best Practices

1. **Secrets Management**
   - Use Azure Key Vault for production secrets
   - Never commit real secrets to version control
   - Use Kubernetes secrets for sensitive data

2. **Network Security**
   - Services communicate internally via service names
   - External access only through ingress
   - SSL/TLS encryption for all external traffic

3. **Resource Limits**
   - CPU and memory limits defined for all containers
   - Prevents resource exhaustion

### Production Security Checklist

- [ ] Update all secrets with real values
- [ ] Configure Azure Key Vault integration
- [ ] Set up network policies
- [ ] Configure RBAC
- [ ] Enable pod security policies
- [ ] Set up monitoring and alerting

## 📊 Monitoring

### Health Checks

All services include health checks:

- **Liveness Probe**: Restarts container if unhealthy
- **Readiness Probe**: Determines if traffic should be sent

### Logging

- Structured JSON logging
- Centralized logging via Azure Monitor
- Log levels configurable via ConfigMap

## 🔄 Scaling

### Horizontal Pod Autoscaling (HPA)

For production, consider adding HPA:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 🛠️ Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Check if images exist in ACR
   az acr repository list --name your-acr-name
   
   # Update image pull secrets
   kubectl create secret docker-registry acr-secret \
     --docker-server=your-acr-name.azurecr.io \
     --docker-username=your-username \
     --docker-password=your-password
   ```

2. **Pod Not Starting**
   ```bash
   # Check pod events
   kubectl describe pod <pod-name> -n <namespace>
   
   # Check pod logs
   kubectl logs <pod-name> -n <namespace>
   ```

3. **Service Not Accessible**
   ```bash
   # Check service endpoints
   kubectl get endpoints -n <namespace>
   
   # Check ingress status
   kubectl get ingress -n <namespace>
   ```

### Debug Commands

```bash
# Get all resources in namespace
kubectl get all -n dnd-campaign-organizer

# Check pod status
kubectl get pods -n dnd-campaign-organizer

# View logs for a service
kubectl logs -l app=api -n dnd-campaign-organizer

# Port forward to debug
kubectl port-forward svc/api-service 4000:4000 -n dnd-campaign-organizer
```

## 🚀 Next Steps

1. **Set up Azure Resources**
   - Create AKS cluster
   - Set up Azure Container Registry
   - Configure Azure Key Vault

2. **CI/CD Pipeline**
   - Build and push Docker images
   - Deploy to Kubernetes
   - Automated testing

3. **Monitoring & Observability**
   - Azure Monitor integration
   - Prometheus/Grafana setup
   - Application Insights

4. **Security Hardening**
   - Network policies
   - Pod security policies
   - RBAC configuration

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/) 