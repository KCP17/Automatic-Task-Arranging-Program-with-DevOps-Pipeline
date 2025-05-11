require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'webrick'

class PrometheusMetrics
  def initialize(port = 9090)
    @registry = Prometheus::Client.registry
    @port = port
    
    # Define metrics
    @tasks_created = Prometheus::Client::Counter.new(
      :tasks_created_total,
      docstring: 'Total number of tasks created',
      labels: [:set_id]
    )
    
    @sets_created = Prometheus::Client::Counter.new(
      :sets_created_total,
      docstring: 'Total number of sets created'
    )
    
    @screen_views = Prometheus::Client::Counter.new(
      :screen_views_total,
      docstring: 'Total screen views',
      labels: [:screen_name]
    )
    
    @button_clicks = Prometheus::Client::Counter.new(
      :button_clicks_total,
      docstring: 'Total button clicks',
      labels: [:button_name]
    )
    
    @errors = Prometheus::Client::Counter.new(
      :application_errors_total,
      docstring: 'Total application errors',
      labels: [:error_type]
    )
    
    @memory_usage = Prometheus::Client::Gauge.new(
      :memory_usage_megabytes,
      docstring: 'Current memory usage in MB'
    )
    
    @session_duration = Prometheus::Client::Gauge.new(
      :session_duration_seconds,
      docstring: 'Current session duration in seconds'
    )
    
    @task_arrangement_duration = Prometheus::Client::Histogram.new(
      :task_arrangement_duration_seconds,
      docstring: 'Time taken to arrange tasks',
      buckets: [0.1, 0.5, 1, 2, 5, 10]
    )
    
    # Register metrics
    @registry.register(@tasks_created)
    @registry.register(@sets_created)
    @registry.register(@screen_views)
    @registry.register(@button_clicks)
    @registry.register(@errors)
    @registry.register(@memory_usage)
    @registry.register(@session_duration)
    @registry.register(@task_arrangement_duration)
    
    # Track session start
    @session_start = Time.now
    
    # Start metrics server in a separate thread
    start_metrics_server
    
    # Start background metrics collection
    start_background_collection
  end
  
  def track_task_created(set_id)
    @tasks_created.increment(labels: { set_id: set_id.to_s })
  end
  
  def track_set_created
    @sets_created.increment
  end
  
  def track_screen_view(screen_name)
    @screen_views.increment(labels: { screen_name: screen_name })
  end
  
  def track_button_click(button_name)
    @button_clicks.increment(labels: { button_name: button_name })
  end
  
  def track_error(error_type, error_message = nil)
    @errors.increment(labels: { error_type: error_type })
  end
  
  def track_task_arrangement_time
    start_time = Time.now
    yield
    duration = Time.now - start_time
    @task_arrangement_duration.observe(duration)
  end

  private
  
  def start_metrics_server
    @server_thread = Thread.new do
      server = WEBrick::HTTPServer.new(Port: @port, Logger: WEBrick::Log.new(nil, 0))
      
      server.mount_proc '/metrics' do |req, res|
        res.content_type = 'text/plain; version=0.0.4'
        res.body = Prometheus::Client::Formats::Text.marshal(@registry)
      end
      
      server.start
    end
  end
  
  def start_background_collection
    @collection_thread = Thread.new do
      loop do
        # Update memory usage
        memory_mb = get_memory_usage
        @memory_usage.set(memory_mb)
        
        # Update session duration
        duration = Time.now - @session_start
        @session_duration.set(duration)
        
        sleep 10 # Update every 10 seconds
      end
    end
  end
  
  def get_memory_usage
    # Windows-specific memory collection
    begin
      result = `wmic process where processid=#{Process.pid} get WorkingSetSize /format:value`
      bytes = result.match(/WorkingSetSize=(\d+)/)[1].to_i
      bytes / (1024.0 * 1024.0) # Convert to MB
    rescue
      0
    end
  end
  
end