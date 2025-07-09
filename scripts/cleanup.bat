@echo off
echo 🧹 Running cleanup...
call npm run cleanup
if %errorlevel% neq 0 exit /b %errorlevel%
echo ✅ Cleanup complete!
exit /b 0 