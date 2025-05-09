@echo off
echo Deploying to test environment...

REM Tag with build number for version tracking
docker build -t automatic-task-arranging:%VERSION% .

REM Tag as latest for easy reference
docker tag automatic-task-arranging:%VERSION% automatic-task-arranging:latest

REM Save the previous version for rollback if needed
docker tag automatic-task-arranging:latest automatic-task-arranging:previous || echo No previous version to backup

REM Deploy using docker-compose
docker-compose up -d

REM Verify deployment
timeout /t 10
docker ps | findstr automatic-task-arranging-test
if %ERRORLEVEL% NEQ 0 (
    echo Deployment verification failed!
    exit /b 1
) else (
    echo Deployment successful!
)