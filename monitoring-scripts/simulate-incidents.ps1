# Docker-friendly incident simulation for Prometheus monitoring

Write-Host "Starting Docker container incident simulation..."

# Check if container is running
$container = docker ps | Select-String "automatic-task-arranging-monitoring"
if (-not $container) {
    Write-Error "Monitoring container is not running. Please start it first."
    exit 1
}

Write-Host "Found monitoring container: $container"
Write-Host "Beginning metrics simulation..."

# Generate metric traffic by accessing the metrics endpoint repeatedly
Write-Host "Simulating normal usage with metric requests..."
for ($i = 0; $i -lt 10; $i++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:9093/metrics" -UseBasicParsing -TimeoutSec 1 | Out-Null
        Write-Host "Request $($i+1) completed"
    } catch {
        Write-Warning "Request $($i+1) failed: $_"
    }
    Start-Sleep -Seconds 1
}

# Simulate error spike by making rapid requests
Write-Host "Simulating error spike with rapid requests..."
for ($i = 0; $i -lt 50; $i++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:9093/metrics" -UseBasicParsing -TimeoutSec 0.2 | Out-Null
    } catch {
        # Expected timeouts - this is part of the simulation
    }
    Start-Sleep -Milliseconds 100
}

# Simulate high CPU usage in the container
Write-Host "Simulating high CPU usage in container..."
docker exec automatic-task-arranging-monitoring sh -c "for i in {1..10000}; do echo \$i > /dev/null; done" 2>$null

# Monitor the metrics for a while
Write-Host "Monitoring metrics for 30 seconds..."
for ($i = 0; $i -lt 6; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9093/metrics" -UseBasicParsing
        $metrics = $response.Content
        
        # Look for interesting metrics
        if ($metrics -match "memory_usage_megabytes\s+([0-9.]+)") {
            $memoryUsage = $matches[1]
            Write-Host "Current memory usage: $memoryUsage MB"
        }
        
        if ($metrics -match "session_duration_seconds\s+([0-9.]+)") {
            $sessionDuration = $matches[1]
            Write-Host "Session duration: $sessionDuration seconds"
        }
    } catch {
        Write-Warning "Failed to get metrics: $_"
    }
    
    Start-Sleep -Seconds 5
}

Write-Host "Incident simulation completed successfully"