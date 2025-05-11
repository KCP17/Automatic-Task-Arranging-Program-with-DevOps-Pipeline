# Simulate incidents for Prometheus monitoring

Write-Host "Starting incident simulation..."

# Create test runner script
$testScript = @'
require './AutomaticTaskArranging'

class IncidentSimulator
  def self.run
    # Start the application
    app = AutoTaskArrangement.new
    app_thread = Thread.new { app.show }
    
    # Wait for initialization
    sleep 3
    
    puts "Simulating normal usage..."
    # Simulate normal operations
    5.times do |i|
      app.instance_variable_get(:@metrics).track_task_created(i)
      app.instance_variable_get(:@metrics).track_button_click("button_#{i}")
      sleep 1
    end
    
    puts "Simulating error spike..."
    # Simulate error spike
    10.times do |i|
      app.instance_variable_get(:@metrics).track_error("test_error", "Simulated error #{i}")
    end
    
    puts "Simulating memory leak..."
    # Simulate memory growth
    memory_hog = []
    10.times do
      memory_hog << "x" * 10_000_000  # 10MB strings
      sleep 2
    end
    
    puts "Simulating slow task arrangement..."
    # Simulate slow operation
    app.instance_variable_get(:@metrics).track_task_arrangement_time do
      sleep 7  # Simulate slow arrangement
    end
    
    # Keep running for monitoring
    sleep 30
    
    app.close
    app_thread.join
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace[0..5]
  end
end

IncidentSimulator.run
'@

$testScript | Out-File -FilePath "incident_simulator.rb" -Encoding utf8

# Run the simulation
ruby incident_simulator.rb

# Cleanup
Remove-Item "incident_simulator.rb"

Write-Host "Incident simulation completed"