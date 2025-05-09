@echo off
echo Rolling back to previous version...

REM Check if previous version exists
docker image inspect automatic-task-arranging:previous
if %ERRORLEVEL% NEQ 0 (
    echo No previous version found for rollback!
    exit /b 1
)

REM Stop current container
docker stop automatic-task-arranging-test
docker rm automatic-task-arranging-test

REM Deploy previous version
docker tag automatic-task-arranging:previous automatic-task-arranging:latest
docker-compose up -d

echo Rollback completed!