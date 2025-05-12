# Check Prometheus metrics

Write-Host "Checking Prometheus metrics..."

# Query Prometheus for current metrics
$baseUrl = "http://localhost:9095"

# Function to query Prometheus
function Query-Prometheus {
    param([string]$query)
    
    $encodedQuery = [System.Uri]::EscapeDataString($query)
    $url = "$baseUrl/api/v1/query?query=$encodedQuery"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get
        return $response.data.result
    } catch {
        Write-Host "Error querying Prometheus: $_"
        return $null
    }
}

# Check various metrics
Write-Host "`nCurrent Metrics:"
Write-Host "----------------"

# Memory usage
$memory = Query-Prometheus "memory_usage_megabytes"
if ($memory) {
    Write-Host "Memory Usage: $($memory[0].value[1]) MB"
}

# Tasks created
$tasks = Query-Prometheus "tasks_created_total"
if ($tasks) {
    $total = 0
    foreach ($result in $tasks) {
        $total += [int]$result.value[1]
    }
    Write-Host "Total Tasks Created: $total"
}

# Error rate
$errors = Query-Prometheus "rate(application_errors_total[5m])"
if ($errors) {
    $errorRate = 0
    foreach ($result in $errors) {
        $errorRate += [double]$result.value[1]
    }
    Write-Host "Error Rate (5m): $errorRate errors/sec"
}

# Session duration
$duration = Query-Prometheus "session_duration_seconds"
if ($duration) {
    $seconds = [int]$duration[0].value[1]
    $minutes = [Math]::Round($seconds / 60, 2)
    Write-Host "Session Duration: $minutes minutes"
}

# Check for active alerts
Write-Host "`nActive Alerts:"
Write-Host "--------------"

$alertsUrl = "$baseUrl/api/v1/alerts"
try {
    $alerts = Invoke-RestMethod -Uri $alertsUrl -Method Get
    if ($alerts.data.alerts.Count -eq 0) {
        Write-Host "No active alerts"
    } else {
        foreach ($alert in $alerts.data.alerts) {
            Write-Host "- $($alert.labels.alertname): $($alert.state)"
            Write-Host "  $($alert.annotations.description)"
        }
    }
} catch {
    Write-Host "Error checking alerts: $_"
}