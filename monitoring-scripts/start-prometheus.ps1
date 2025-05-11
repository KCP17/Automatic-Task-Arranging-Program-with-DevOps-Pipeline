# Start Prometheus monitoring stack

param(
    [string]$PrometheusPath = "C:\prometheus",
    [string]$ConfigPath = "$PWD\prometheus.yml",
    [string]$AlertRulesPath = "$PWD\alert-rules.yml"
)

Write-Host "Starting Prometheus monitoring stack..."

# Copy config files to Prometheus directory
Copy-Item $ConfigPath "$PrometheusPath\prometheus.yml" -Force
Copy-Item $AlertRulesPath "$PrometheusPath\alert-rules.yml" -Force

# Update Prometheus config to include alert rules
$config = @"
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert-rules.yml"

scrape_configs:
  - job_name: 'automatic-task-arranging'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 10s
    scrape_timeout: 5s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093
"@

$config | Out-File -FilePath "$PrometheusPath\prometheus.yml" -Encoding utf8 -Force

# Start Prometheus
$prometheusJob = Start-Job -ScriptBlock {
    param($path)
    Set-Location $path
    .\prometheus.exe --config.file=prometheus.yml --storage.tsdb.path=data
} -ArgumentList $PrometheusPath

Write-Host "Prometheus started with Job ID: $($prometheusJob.Id)"
Write-Host "Prometheus UI available at: http://localhost:9095"

# Save job info
@{
    PrometheusJobId = $prometheusJob.Id
    PrometheusUrl = "http://localhost:9095"
} | ConvertTo-Json | Out-File -FilePath "prometheus-info.json"

return $prometheusJob