@echo off
echo 🎲 Starting D&D Campaign Organizer Services...
echo.

REM Check if we're in the right directory
if not exist "package.json" (
    echo ❌ Error: Please run this script from the project root directory
    pause
    exit /b 1
)

REM Check for .env files
if not exist "apps\api\.env" (
    echo ⚠️  Warning: apps\api\.env not found. API may not work properly.
)

if not exist "apps\discord-bot\.env" (
    echo ⚠️  Warning: apps\discord-bot\.env not found. Discord bot may not work properly.
)

echo 📦 Installing dependencies...
call npm install

echo.
echo 🚀 Starting all services...
echo.

REM Start all services
call npm run dev:all

pause 