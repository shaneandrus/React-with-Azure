# Start All Services Script
# This script starts all the services for the D&D Campaign Organizer

Write-Host "🎲 Starting D&D Campaign Organizer Services..." -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Error: Please run this script from the project root directory" -ForegroundColor Red
    exit 1
}

# Check if .env files exist
$envFiles = @(
    "apps/api/.env",
    "apps/discord-bot/.env"
)

foreach ($envFile in $envFiles) {
    if (-not (Test-Path $envFile)) {
        Write-Host "⚠️  Warning: $envFile not found. Some services may not work properly." -ForegroundColor Yellow
    }
}

Write-Host "📦 Installing dependencies..." -ForegroundColor Cyan
npm install

Write-Host ""
Write-Host "🚀 Starting all services..." -ForegroundColor Green
Write-Host ""

# Start all services using turbo
try {
    npm run dev:all
} catch {
    Write-Host "❌ Error starting services: $_" -ForegroundColor Red
    exit 1
} 