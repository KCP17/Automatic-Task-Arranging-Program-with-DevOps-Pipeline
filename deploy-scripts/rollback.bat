@echo off
echo Rolling back to previous version...

REM Check if previous version exists
docker image inspect automatic_task_arranging:previous
if %ERRORLEVEL% NEQ 0 (
    echo No previous version found for rollback!
    exit /b 1
)

REM Stop current container
docker stop automatic_task_arranging-test
docker rm automatic_task_arranging-test

REM Deploy previous version
docker tag automatic_task_arranging:previous automatic_task_arranging:latest
docker-compose up -d

echo Rollback completed!