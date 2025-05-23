@echo off
echo Deploying to test environment...

REM Check if current version exists
docker image inspect automatic_task_arranging:%VERSION% >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Image automatic_task_arranging:%VERSION% not found!
    exit /b 1
)

REM Tag as latest
docker tag automatic_task_arranging:%VERSION% automatic_task_arranging:latest

REM Backup current running version as previous (if any)
docker tag automatic_task_arranging:latest automatic_task_arranging:previous 2>nul || echo No current version to backup

REM Deploy with version
docker-compose down
docker-compose up -d