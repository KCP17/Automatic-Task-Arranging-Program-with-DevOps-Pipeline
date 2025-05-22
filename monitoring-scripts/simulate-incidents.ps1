# Docker-friendly incident simulation for Prometheus monitoring

Write-Host "Starting Docker container incident simulation..."

# Check if container is running
$containerName = "automatic_task_arranging-production"
$container = docker ps | Select-String $containerName
if (-not $container) {
    Write-Error "Monitoring container '$containerName' is not running. Please start it first."
    exit 1
}

Write-Host "Found monitoring container: $container"
Write-Host "Beginning metrics simulation for LowActivity alert..."

# Step 1: Create some initial tasks to establish a metric, then stop creating tasks
Write-Host "Creating initial tasks to establish the metric..."
docker exec $containerName ruby -e "
    # Load the existing metrics class
    require_relative './prometheus_metrics'
    
    # Create metrics instance
    metrics = PrometheusMetrics.new(9093) if !defined?(METRICS_INSTANCE)
    
    # Create a few tasks to establish the metric
    3.times do |i|
      metrics.track_task_created(1)
      puts 'Task created in set 1'
    end
    
    puts 'Initial tasks created - no more will be created'
"

# Step 2: Set the session duration > 300 seconds
Write-Host "Setting session duration > 300 seconds..."
docker exec $containerName ruby -e "
    # Load the existing metrics class
    require_relative './prometheus_metrics'
    
    # Create metrics instance or use existing
    metrics = PrometheusMetrics.new(9093) if !defined?(METRICS_INSTANCE)
    
    # Set session duration to trigger alert
    metrics.instance_variable_get(:@session_duration).set(350)
    puts 'Session duration set to 350 seconds'
    
    # Simulate other activity but NO task creation
    metrics.track_screen_view('home_screen')
    metrics.track_button_click('menu_button')
    
    puts 'Session duration condition established'
"

# Make metrics available to Prometheus
Write-Host "Making metrics available to Prometheus..."
Invoke-WebRequest -Uri "http://localhost:9093/metrics" -UseBasicParsing -TimeoutSec 2 | Out-Null

# Function to check the rate of task creation
function Check-TaskCreationRate {
    try {
        $rateQuery = "rate(tasks_created_total[10m])"
        $encodedQuery = [System.Uri]::EscapeUriString("http://localhost:9095/api/v1/query?query=$rateQuery")
        $response = Invoke-WebRequest -Uri $encodedQuery -UseBasicParsing
        $result = $response.Content | ConvertFrom-Json
        
        if ($result.data.result.Count -eq 0) {
            return "No data - likely zero"
        }
        
        $rates = $result.data.result | ForEach-Object { $_.value[1] }
        return $rates
    }
    catch {
        Write-Warning "Failed to query task creation rate: $_"
        return "Error"
    }
}

# Step 3: Wait the full 10 minutes to ensure rate(tasks_created_total[10m]) == 0
$waitTimeMinutes = 10
$totalSeconds = $waitTimeMinutes * 60
$interval = 60  # Check every minute

Write-Host "Waiting $waitTimeMinutes minutes to ensure task creation rate will be 0..."
Write-Host "This is necessary because the alert condition uses rate(tasks_created_total[10m]) == 0"
Write-Host "We'll check the rate every minute to show progress..."

for ($i = 0; $i -lt $waitTimeMinutes; $i++) {
    $remainingMinutes = $waitTimeMinutes - $i
    Write-Host "Waiting... $remainingMinutes minutes remaining"
    
    # Check the current rate for informational purposes
    $rate = Check-TaskCreationRate
    Write-Host "Current task creation rate: $rate (should approach 0 as time passes)"
    
    # Make metrics available periodically
    Invoke-WebRequest -Uri "http://localhost:9093/metrics" -UseBasicParsing -TimeoutSec 2 | Out-Null
    
    if ($i -lt ($waitTimeMinutes - 1)) {
        Start-Sleep -Seconds $interval
    }
}

Write-Host "10-minute wait period completed. The rate(tasks_created_total[10m]) should now be 0."
Write-Host "Both alert conditions should now be satisfied:"
Write-Host "  1. session_duration_seconds > 300 (set to 350)"
Write-Host "  2. rate(tasks_created_total[10m]) == 0 (after waiting 10 minutes)"

# Final verification of metrics
$rate = Check-TaskCreationRate
Write-Host "Final task creation rate: $rate (should be 0 or 'No data - likely zero')"

# Function to check alert status
function Check-AlertStatus {
    param (
        [string]$alertName
    )
    
    try {
        # Query Prometheus API for alerts
        $alertsResponse = Invoke-WebRequest -Uri "http://localhost:9095/api/v1/alerts" -UseBasicParsing
        $alerts = $alertsResponse.Content | ConvertFrom-Json
        
        # Look for our specific alert
        $foundAlert = $false
        $alertState = "Not found"
        $alertDetails = $null
        
        foreach ($alert in $alerts.data.alerts) {
            if ($alert.labels.alertname -eq $alertName) {
                $foundAlert = $true
                $alertState = $alert.state
                $alertDetails = $alert
                break
            }
        }
        
        return @{
            Found = $foundAlert
            State = $alertState
            Details = $alertDetails
        }
    }
    catch {
        Write-Warning "Failed to check alert status: $_"
        return @{
            Found = $false
            State = "Error checking"
            Details = $null
        }
    }
}

# Step 4: Now that both conditions are met, monitor for alert to fire
# The alert rule has "for: 5m" so we need to wait up to 5 minutes for it to transition from pending to firing
Write-Host "Monitoring for alert to fire (can take up to 5 minutes due to 'for: 5m' in the alert rule)..."

$maxAlertWaitTime = 6  # 6 minutes (slightly longer than the 5 min in alert rule)
$alertWaitInterval = 30  # Check every 30 seconds
$elapsedMinutes = 0
$alertFired = $false

while ($elapsedMinutes -lt $maxAlertWaitTime -and -not $alertFired) {
    # Check if alert is firing
    $alertStatus = Check-AlertStatus -alertName "LowActivity"
    
    if ($alertStatus.Found) {
        Write-Host "LowActivity alert found with state: $($alertStatus.State)"
        
        if ($alertStatus.State -eq "firing") {
            Write-Host "ALERT TRIGGERED! The LowActivity alert is now firing."
            $alertFired = $true
        }
        elseif ($alertStatus.State -eq "pending") {
            Write-Host "Alert is pending - waiting for it to fire..."
        }
    }
    else {
        Write-Host "LowActivity alert not found yet. This could mean the alert condition hasn't been detected or alerting rules haven't been evaluated yet."
    }
    
    if (-not $alertFired) {
        Write-Host "Waiting $alertWaitInterval seconds before checking again... ($elapsedMinutes/$maxAlertWaitTime minutes elapsed)"
        Start-Sleep -Seconds $alertWaitInterval
        $elapsedMinutes += ($alertWaitInterval / 60)
    }
}

if ($alertFired) {
    Write-Host "SUCCESS: LowActivity alert was successfully triggered!"
} else {
    Write-Host "The alert did not fire within the expected time frame. Possible reasons:"
    Write-Host "1. The rate(tasks_created_total[10m]) might not be exactly 0 yet"
    Write-Host "2. The session_duration_seconds might not be correctly set"
    Write-Host "3. Prometheus rules may not be evaluating as expected"
    Write-Host "4. The alert rule might be configured differently than expected"
    
    # Check metrics explicitly to help diagnose
    Write-Host "`nChecking final metric values to diagnose:"
    
    # Check session duration
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9093/metrics" -UseBasicParsing
        $metrics = $response.Content
        
        if ($metrics -match "session_duration_seconds\s+([0-9.]+)") {
            $sessionDuration = $matches[1]
            Write-Host "Session duration: $sessionDuration seconds (should be > 300)"
            if ([double]$sessionDuration -le 300) {
                Write-Host "ISSUE FOUND: Session duration is not > 300 seconds"
            }
        } else {
            Write-Host "ISSUE FOUND: Session duration metric not found"
        }
    } catch {
        Write-Host "Error checking metrics: $_"
    }
    
    # Check task creation rate again
    $rate = Check-TaskCreationRate
    Write-Host "Task creation rate: $rate (should be 0)"
    if ($rate -ne "No data - likely zero" -and $rate -ne "0") {
        Write-Host "ISSUE FOUND: Task creation rate is not 0"
    }
}

Write-Host "LowActivity incident simulation completed"
Write-Host "For manual verification, check the Prometheus UI at http://localhost:9095/alerts"