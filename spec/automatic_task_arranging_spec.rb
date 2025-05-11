require 'rspec'
require_relative '../AutomaticTaskArranging'

RSpec.describe AutoTaskArrangement do
  # Mock Gosu and prevent actual window creation
  before do
    # Stub Gosu components
    allow_any_instance_of(AutoTaskArrangement).to receive(:show)
    allow(Gosu::Font).to receive(:new).and_return(double(height: 20, text_width: 100))
    allow(Gosu::Image).to receive(:new).and_return(double(draw: nil))
    
    # Mock PrometheusMetrics to prevent server startup
    mock_metrics = double('PrometheusMetrics')
    allow(PrometheusMetrics).to receive(:new).and_return(mock_metrics)
    allow(mock_metrics).to receive(:track_screen_view)
    allow(mock_metrics).to receive(:track_button_click)
    allow(mock_metrics).to receive(:track_task_created)
    allow(mock_metrics).to receive(:track_set_created)
    allow(mock_metrics).to receive(:track_error)
    allow(mock_metrics).to receive(:track_task_arrangement_time).and_yield
    
    # Stub File.exist? to prevent loading prometheus_metrics.rb
    allow(File).to receive(:exist?).with('./prometheus_metrics.









').and_return(false)
    allow(File).to receive(:exist?).and_call_original
  end
  
  describe '#initialize' do
    it 'initializes without prometheus metrics when file does not exist' do
      app = AutoTaskArrangement.new
      expect(app.instance_variable_get(:@metrics)).to be_nil
    end
    
    it 'safely handles metrics operations when metrics is nil' do
      app = AutoTaskArrangement.new
      
      # These should not raise errors even with nil metrics
      expect { app.send(:switch_screens) }.not_to raise_error
    end
  end
  
  describe 'metrics tracking with nil metrics' do
    let(:app) { AutoTaskArrangement.new }
    
    before do
      app.instance_variable_set(:@metrics, nil)
      allow(app).to receive(:display_home_screen)
      allow(app).to receive(:display_screen_1)
      allow(app).to receive(:draw_navigation_bar)
    end
    
    it 'safely handles nil metrics in switch_screens' do
      app.instance_variable_set(:@screen_choice, 0)
      expect { app.switch_screens }.not_to raise_error
    end
    
    it 'safely handles nil metrics in button clicks' do
      allow(app).to receive(:mouse_x).and_return(650)
      allow(app).to receive(:mouse_y).and_return(925)
      allow(app).to receive(:button_down?).and_return(true)
      
      expect { app.mouse_clicked_save_button }.not_to raise_error
    end
  end
  
  describe 'metrics integration when available' do
    let(:app) { AutoTaskArrangement.new }
    let(:mock_metrics) { double('PrometheusMetrics') }
    
    before do
      app.instance_variable_set(:@metrics, mock_metrics)
      allow(app).to receive(:display_home_screen)
      allow(app).to receive(:display_screen_1)
      allow(app).to receive(:draw_navigation_bar)
    end
    
    it 'tracks screen views when metrics is available' do
      expect(mock_metrics).to receive(:track_screen_view).with('home')
      app.instance_variable_set(:@screen_choice, 0)
      app.switch_screens
    end
    
    it 'tracks button clicks when metrics is available' do
      allow(app).to receive(:mouse_x).and_return(650)
      allow(app).to receive(:mouse_y).and_return(925)
      allow(app).to receive(:button_down?).and_return(true)
      
      expect(mock_metrics).to receive(:track_button_click).with('save')
      app.mouse_clicked_save_button
    end
  end
end