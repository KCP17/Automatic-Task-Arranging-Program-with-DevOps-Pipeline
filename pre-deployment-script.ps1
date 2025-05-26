# Get Octopus variables
$appDirectory = $OctopusParameters["AppDirectory"]

# Ensure application directory exists
if (!(Test-Path $appDirectory)) {
    New-Item -ItemType Directory -Path $appDirectory -Force
}

Write-Host "Application directory prepared: $appDirectory"