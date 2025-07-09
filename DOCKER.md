# Docker Setup for D&D Campaign Organizer

This document explains how to use Docker with the D&D Campaign Organizer project.

## 🐳 Quick Start

### Prerequisites
- Docker Desktop installed and running
- Docker Compose installed
- Discord bot token (for Discord bot service)

### Environment Setup
1. Create a `.env` file in the root directory:
   ```bash
   DISCORD_TOKEN=your_discord_bot_token_here
   ```

2. Create environment files for individual services:
   ```bash
   # apps/api/.env
   PORT=4000
   NODE_ENV=production

   # apps/discord-bot/.env
   DISCORD_TOKEN=your_discord_bot_token_here
   ```

## 🚀 Production Deployment

### Build and Run All Services
```bash
# Build all services
npm run docker:build

# Start all services
npm run docker:up

# Stop all services
npm run docker:down
```

### Individual Service Commands
```bash
# Build specific service
docker-compose build api
docker-compose build frontend
docker-compose build discord-bot

# Run specific service
docker-compose up api
docker-compose up frontend
docker-compose up discord-bot
```

## 🔧 Development with Docker

### Development Mode (Hot Reload)
```bash
# Start development environment
npm run docker:dev

# Build development images
npm run docker:dev:build

# Stop development environment
npm run docker:dev:down
```

### Development Features
- **Hot Reload**: Code changes are reflected immediately
- **Volume Mounts**: Source code is mounted into containers
- **Node Modules**: Cached in Docker volumes for faster builds

## 📁 Dockerfile Structure

### Production Dockerfiles
- `apps/api/Dockerfile` - Multi-stage build for API
- `apps/frontend/Dockerfile` - Multi-stage build for React app
- `apps/discord-bot/Dockerfile` - Multi-stage build for Discord bot

### Development Dockerfiles
- `apps/api/Dockerfile.dev` - Development with hot reload
- `apps/frontend/Dockerfile.dev` - Development with Vite dev server
- `apps/discord-bot/Dockerfile.dev` - Development with nodemon

## 🔍 Service Access

### Production
- **Frontend**: http://localhost:5173
- **API**: http://localhost:4000
- **GraphQL Playground**: http://localhost:4000/graphql
- **GraphQL Playground UI**: http://localhost:4000/playground

### Development
- **Frontend**: http://localhost:5173 (with hot reload)
- **API**: http://localhost:4000 (with hot reload)
- **Discord Bot**: Running in background

## 🛠️ Docker Commands Reference

### Build Commands
```bash
# Build all services
docker-compose build

# Build specific service
docker-compose build api

# Build without cache
docker-compose build --no-cache
```

### Run Commands
```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Start specific service
docker-compose up api

# View logs
docker-compose logs -f
```

### Management Commands
```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Clean Docker system
npm run docker:clean

# View running containers
docker-compose ps
```

## 🔒 Security Considerations

### Environment Variables
- Never commit `.env` files to version control
- Use Docker secrets for production deployments
- Consider using Azure Key Vault for production secrets

### Network Security
- Services communicate via internal Docker network
- Only necessary ports are exposed to host
- Consider using reverse proxy for production

## 📊 Monitoring and Logs

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs api

# Follow logs
docker-compose logs -f frontend
```

### Health Checks
- Frontend: `http://localhost:5173/health`
- API: `http://localhost:4000/health` (if implemented)

## 🚨 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check what's using a port
netstat -ano | findstr :4000

# Kill process using port
taskkill /PID <process_id> /F
```

#### Build Failures
```bash
# Clean build cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache
```

#### Container Won't Start
```bash
# Check container logs
docker-compose logs <service_name>

# Check container status
docker-compose ps
```

### Debug Commands
```bash
# Enter running container
docker-compose exec api sh

# View container details
docker-compose exec api cat /app/package.json

# Check environment variables
docker-compose exec api env
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Build and Deploy
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Docker images
        run: docker-compose build
      - name: Push to Azure Container Registry
        run: |
          docker tag dnd-campaign-organizer-api:latest ${{ secrets.ACR_REGISTRY }}/api:latest
          docker push ${{ secrets.ACR_REGISTRY }}/api:latest
```

## 📈 Performance Optimization

### Multi-stage Builds
- Production images are optimized for size
- Development images include all dependencies
- Source maps and declarations are excluded from production

### Caching Strategy
- Node modules are cached in Docker layers
- Source code changes don't invalidate dependency cache
- Build context is minimized with .dockerignore

### Resource Limits
```yaml
# Add to docker-compose.yml for production
services:
  api:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

## 🎯 Next Steps

1. **Kubernetes Deployment**: Create K8s manifests for Azure AKS
2. **Azure Container Registry**: Set up ACR for image storage
3. **Monitoring**: Add Prometheus/Grafana for metrics
4. **Logging**: Implement centralized logging with ELK stack
5. **Security**: Add security scanning with Trivy or Snyk

---

For more information, see the main [README.md](README.md) file. 