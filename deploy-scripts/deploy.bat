@echo off

REM Check if current version exists, if not then stops pipeline
docker image inspect automatic_task_arranging:%VERSION% >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Image automatic_task_arranging:%VERSION% not found!
    exit /b 1
)

REM Tag current version as latest
docker tag automatic_task_arranging:%VERSION% automatic_task_arranging:latest

REM Backup current version as previous (if any)
docker tag automatic_task_arranging:latest automatic_task_arranging:previous 2>nul || echo No current version to backup

REM Deploy the current version with Docker Compose (stop the current container and start a new one)
docker-compose down
docker-compose up -d