@echo off
echo ==============================================
echo Starting PicX in Docker...
echo ==============================================
docker compose up -d --build
if errorlevel 1 (
    echo [ERROR] Failed to start PicX with docker compose.
    pause
    exit /b %errorlevel%
)
echo ==============================================
echo PicX started successfully!
echo Access PicX at: http://localhost:8088
echo ==============================================
pause
