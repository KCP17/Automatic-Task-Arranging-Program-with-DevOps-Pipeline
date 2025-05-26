# Get Octopus variables
$appDirectory = $OctopusParameters["AppDirectory"]
$logLevel = $OctopusParameters["LogLevel"]
$performanceMode = $OctopusParameters["PerformanceMode"]
$environment = $OctopusParameters["Octopus.Environment.Name"]

# Get package version - use the correct Octopus variable
$packageVersion = $OctopusParameters["Octopus.Release.Number"]
Write-Host "Package version: $packageVersion"

# Pull the Docker image from Docker Hub
Write-Host "Pulling Docker image from Docker Hub..."
docker pull kcp17/automatic_task_arranging:$packageVersion

# Tag for current environment
$environmentLower = $environment.ToLower()
Write-Host "Tagging image for $environment environment..."
docker tag kcp17/automatic_task_arranging:$packageVersion automatic_task_arranging:$environmentLower

# Create config directory
$configDir = Join-Path $appDirectory "config"
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force
}

# Create environment-specific config file
$configContent = @"
# Environment: $environment
# Generated: $(Get-Date)
PERFORMANCE_SETTINGS = {
  log_level: '$logLevel',
  performance_mode: '$performanceMode',
  environment: '$environment'
}
"@

# Write config file
Set-Content -Path "$configDir\environment.rb" -Value $configContent

# Create environment-specific docker-compose file
$dockerComposeContent = @"
services:
  app:
    image: automatic_task_arranging:$environmentLower
    container_name: automatic_task_arranging-$environmentLower
    ports:
      - "9091:9091"
    environment:
      - DISPLAY=:0
      - VERSION=$packageVersion
      - ENVIRONMENT=$environment
      - LOG_LEVEL=$logLevel
      - PERFORMANCE_MODE=$performanceMode
    volumes:
      - ./config:/app/config:ro
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
    restart: unless-stopped
"@

$dockerComposeFile = Join-Path $appDirectory "docker-compose-$environmentLower.yml"
Set-Content -Path $dockerComposeFile -Value $dockerComposeContent

# Stop existing container
Write-Host "Stopping existing container..."
Set-Location $appDirectory
docker-compose -f docker-compose-$environmentLower.yml down

# Start new container
Write-Host "Starting container for $environment..."
docker-compose -f docker-compose-$environmentLower.yml up -d

Write-Host "Docker container deployed to $environment environment"