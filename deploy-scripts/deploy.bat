@echo off
echo Deploying to test environment...

REM Tag as latest for easy reference
echo Tagging as latest...
docker tag automatic_task_arranging:%VERSION% automatic_task_arranging:latest

REM Save the previous version for rollback if needed
echo Backing up previous version...
docker image inspect automatic-task-arranging:previous >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Previous version exists, keeping backup
) else (
    echo No previous version to backup
)
docker tag automatic_task_arranging:latest automatic_task_arranging:previous 2>nul || echo Could not tag previous version

REM Deploy using docker-compose
echo Deploying with docker-compose...
docker-compose down
docker-compose up -d