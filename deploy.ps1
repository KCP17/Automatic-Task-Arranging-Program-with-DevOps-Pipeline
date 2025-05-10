# Octopus deployment script
$ErrorActionPreference = "Stop"

# Get Octopus variables
$appDirectory = $OctopusParameters["AppDirectory"]
$logLevel = $OctopusParameters["LogLevel"]
$performanceMode = $OctopusParameters["PerformanceMode"]
$environment = $OctopusParameters["Octopus.Environment.Name"]

# Ensure application directory exists
if (!(Test-Path $appDirectory)) {
    New-Item -ItemType Directory -Path $appDirectory -Force
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
Set-Content -Path "$appDirectory\config\environment.rb" -Value $configContent

# Copy all application files
Copy-Item -Path "*.rb" -Destination $appDirectory -Force
Copy-Item -Path "config\*" -Destination "$appDirectory\config" -Force -Recurse

Write-Host "Deployment complete to $environment environment"