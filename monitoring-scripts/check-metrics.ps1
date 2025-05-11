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

# Generate metrics report
$report = @"
<!DOCTYPE html>
<html>
<head>
    <title>Prometheus Metrics Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric { margin: 10px 0; padding: 10px; border: 1px solid #ddd; }
        .alert { color: red; }
    </style>
</head>
<body>
    <h1>Prometheus Metrics Report</h1>
    <p>Generated at: $(Get-Date)</p>
    
    <div class="metric">
        <h3>Memory Usage</h3>
        <p>Current: $($memory[0].value[1]) MB</p>
    </div>
    
    <div class="metric">
        <h3>Application Activity</h3>
        <p>Tasks Created: $total</p>
        <p>Session Duration: $minutes minutes</p>
    </div>
    
    <div class="metric">
        <h3>Error Monitoring</h3>
        <p>Error Rate: $errorRate errors/sec</p>
    </div>
    
    <h2>Prometheus Dashboard</h2>
    <p>Access full metrics at: <a href="$baseUrl">$baseUrl</a></p>
    
    <h2>Example Queries</h2>
    <ul>
        <li>Memory trend: <code>memory_usage_megabytes</code></li>
        <li>Task creation rate: <code>rate(tasks_created_total[5m])</code></li>
        <li>Error spike detection: <code>rate(application_errors_total[1m]) > 0.1</code></li>
        <li>P95 task arrangement time: <code>histogram_quantile(0.95, rate(task_arrangement_duration_seconds_bucket[5m]))</code></li>
    </ul>
</body>
</html>
"@

$report | Out-File -FilePath "prometheus-metrics-report.html" -Encoding utf8
Write-Host "`nMetrics report generated: prometheus-metrics-report.html"