# GitHub Actions CI/CD Pipeline

This directory contains the GitHub Actions workflow for the D&D Campaign Organizer project.

## 🚀 Pipeline Overview

The CI/CD pipeline automatically:
- **Builds and tests** your code on every push/PR
- **Builds Docker images** and pushes them to GitHub Container Registry
- **Scans for security vulnerabilities** using Trivy
- **Deploys to development** when pushing to `develop` branch
- **Deploys to production** when pushing to `main` branch
- **Notifies Discord** about deployment status

## 📋 Pipeline Jobs

### 1. **Build and Test** (`build-and-test`)
- Runs on Node.js 18 and 20
- Installs dependencies with `npm ci`
- Runs linting with `npm run lint`
- Builds all packages with `npm run build`
- Checks TypeScript compilation for all apps

### 2. **Docker Build** (`docker-build`)
- Builds and pushes Docker images to GitHub Container Registry
- Uses Docker Buildx for efficient builds
- Implements layer caching for faster builds
- Tags images with branch name, commit SHA, and semantic versions

### 3. **Security Scan** (`security-scan`)
- Scans Docker images for vulnerabilities using Trivy
- Uploads results to GitHub Security tab
- Fails the pipeline if critical vulnerabilities are found

### 4. **Deploy to Development** (`deploy-dev`)
- **Trigger**: Push to `develop` branch
- Deploys to Kubernetes development namespace
- Uses kustomize for configuration management
- Waits for all deployments to be ready

### 5. **Deploy to Production** (`deploy-prod`)
- **Trigger**: Push to `main` branch
- Deploys to Kubernetes production namespace
- Requires manual approval (environment protection)
- Uses kustomize for configuration management

### 6. **Discord Notification** (`notify-discord`)
- Sends deployment notifications to Discord
- Includes repository, branch, commit, and status info
- Only runs after successful deployments

## 🔧 Configuration

### Required Secrets

Add these secrets in your GitHub repository settings:

#### For Azure Deployment (Optional)
```
AZURE_CREDENTIALS          # Azure service principal credentials (JSON)
AKS_RESOURCE_GROUP         # Azure resource group name
AKS_CLUSTER_NAME          # AKS cluster name
```

#### For Discord Notifications (Optional)
```
DISCORD_WEBHOOK           # Discord webhook URL
```

### Environment Protection

Set up environment protection rules in GitHub:

1. **Go to**: Settings → Environments
2. **Create environments**: `development` and `production`
3. **Add protection rules**:
   - **Required reviewers** (for production)
   - **Wait timer** (optional)
   - **Deployment branches** (main only for production)

## 🎯 Usage

### Automatic Triggers
- **Push to `main`**: Build, test, scan, deploy to production
- **Push to `develop`**: Build, test, scan, deploy to development
- **Pull Request**: Build and test only (no deployment)

### Manual Triggers
- **Workflow Dispatch**: Manually trigger the pipeline
- **Branch-specific**: Deploy to specific environments

## 📊 Monitoring

### GitHub Actions Dashboard
- View pipeline runs in the Actions tab
- Check logs for each job
- Monitor build times and success rates

### Security Scanning
- View vulnerability reports in Security tab
- Configure alerts for new vulnerabilities
- Review Trivy scan results

### Deployment Status
- Check deployment status in Environments tab
- View deployment history and rollbacks
- Monitor deployment logs

## 🔍 Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check local build
npm ci
npm run build
npm run lint
```

#### Docker Build Issues
```bash
# Test Docker builds locally
docker build -f apps/frontend/Dockerfile .
docker build -f apps/api/Dockerfile .
docker build -f apps/discord-bot/Dockerfile .
```

#### Deployment Issues
```bash
# Check Kubernetes cluster access
kubectl cluster-info
kubectl get nodes

# Check deployment status
kubectl get pods -n dnd-campaign-organizer-dev
kubectl get pods -n dnd-campaign-organizer
```

#### Azure Authentication Issues
```bash
# Test Azure CLI access
az login
az aks get-credentials --resource-group <rg> --name <cluster>
kubectl cluster-info
```

### Debug Commands

#### Check Pipeline Logs
```bash
# View specific job logs
gh run view <run-id> --log

# Download artifacts
gh run download <run-id>
```

#### Local Testing
```bash
# Test the entire pipeline locally
act -j build-and-test
act -j docker-build
```

## 🚀 Advanced Configuration

### Customizing the Pipeline

#### Add Custom Tests
```yaml
- name: Run custom tests
  run: |
    npm run test:unit
    npm run test:integration
    npm run test:e2e
```

#### Add Code Coverage
```yaml
- name: Generate coverage report
  run: npm run test:coverage
  
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage/lcov.info
```

#### Add Performance Testing
```yaml
- name: Run Lighthouse CI
  uses: treosh/lighthouse-ci-action@v10
  with:
    configPath: './lighthouserc.json'
    uploadArtifacts: true
```

### Environment-Specific Configurations

#### Development Environment
- Faster builds with less caching
- More verbose logging
- Automatic rollback on failure

#### Production Environment
- Stricter security scanning
- Manual approval required
- Blue-green deployment strategy
- Performance monitoring

## 📈 Performance Optimization

### Build Optimization
- **Docker layer caching**: Reduces build times by 50-80%
- **Parallel jobs**: Runs independent jobs simultaneously
- **Selective builds**: Only rebuilds changed components

### Deployment Optimization
- **Rolling updates**: Zero-downtime deployments
- **Health checks**: Ensures deployments are healthy
- **Resource limits**: Prevents resource exhaustion

## 🔒 Security Best Practices

### Secrets Management
- **Never commit secrets**: Use GitHub Secrets
- **Rotate regularly**: Update secrets periodically
- **Principle of least privilege**: Minimal required permissions

### Container Security
- **Base image scanning**: Regular vulnerability scans
- **Multi-stage builds**: Reduce attack surface
- **Non-root users**: Run containers as non-root

### Network Security
- **Private clusters**: Use private AKS clusters
- **Network policies**: Restrict pod-to-pod communication
- **TLS everywhere**: Encrypt all traffic

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/)
- [Trivy Security Scanner](https://aquasecurity.github.io/trivy/)

## 🤝 Contributing

When contributing to the pipeline:

1. **Test locally** before pushing
2. **Update documentation** for new features
3. **Follow security best practices**
4. **Add appropriate tests** for new functionality
5. **Review and approve** changes through PRs

---

**Note**: This pipeline is designed to work with the existing project structure. If you modify the project structure, update the pipeline accordingly. 