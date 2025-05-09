@echo off
echo Deploying to test environment...

REM Ensure VERSION is set (use a default value if not provided)
if "%VERSION%"=="" set VERSION=latest
echo Using version: %VERSION%

REM Tag with build number for version tracking
echo Building Docker image...
docker build -t automatic-task-arranging:%VERSION% .
if %ERRORLEVEL% NEQ 0 (
    echo Docker build failed!
    exit /b 1
)

REM Tag as latest for easy reference
echo Tagging as latest...
docker tag automatic-task-arranging:%VERSION% automatic-task-arranging:latest

REM Save the previous version for rollback if needed
echo Backing up previous version...
docker image inspect automatic-task-arranging:previous >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Previous version exists, keeping backup
) else (
    echo No previous version to backup
)
docker tag automatic-task-arranging:latest automatic-task-arranging:previous 2>nul || echo Could not tag previous version

REM Deploy using docker-compose
echo Deploying with docker-compose...
docker-compose down
docker-compose up -d

REM Verify deployment (using ping instead of timeout to avoid input redirection issue)
echo Waiting for container to start...
ping -n 11 127.0.0.1 >nul

echo Verifying deployment...
docker ps | findstr automatic-task-arranging-test
if %ERRORLEVEL% NEQ 0 (
    echo Deployment verification failed!
    exit /b 1
) else (
    echo Deployment successful!
)