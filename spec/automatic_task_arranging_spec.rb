require 'rspec'
require_relative '../AutomaticTaskArranging'

RSpec.describe AutoTaskArrangement do
  # Mock the Gosu window to prevent it from actually opening
  before do
    allow_any_instance_of(AutoTaskArrangement).to receive(:show)
    allow(Gosu::Font).to receive(:new).and_return(double(height: 20, text_width: 100))
    allow(Gosu::Image).to receive(:new).and_return(double(draw: nil))
  end
  
  describe '#initialize' do
    it 'initializes with prometheus metrics when available' do
      # Mock PrometheusMetrics
      mock_metrics = double('PrometheusMetrics')
      allow(PrometheusMetrics).to receive(:new).and_return(mock_metrics)
      allow(mock_metrics).to receive(:track_screen_view)
      
      # Initialize the app
      app = AutoTaskArrangement.new
      
      # Verify metrics were initialized
      expect(app.instance_variable_get(:@metrics)).to eq(mock_metrics)
    end
    
    it 'handles prometheus metrics initialization failure gracefully' do
      # Make PrometheusMetrics fail
      allow(PrometheusMetrics).to receive(:new).and_raise("Connection error")
      
      # Should not raise error
      expect { AutoTaskArrangement.new }.not_to raise_error
    end
  end
  
  describe '#switch_screens' do
    let(:app) { AutoTaskArrangement.new }
    let(:mock_metrics) { double('PrometheusMetrics') }
    
    before do
      app.instance_variable_set(:@metrics, mock_metrics)
      allow(app).to receive(:display_home_screen)
      allow(app).to receive(:display_screen_1)
      allow(app).to receive(:draw_navigation_bar)
    end
    
    it 'tracks screen views when switching screens' do
      expect(mock_metrics).to receive(:track_screen_view).with('home')
      app.instance_variable_set(:@screen_choice, 0)
      app.switch_screens
      
      expect(mock_metrics).to receive(:track_screen_view).with('create_tasks')
      app.instance_variable_set(:@screen_choice, 1)
      app.switch_screens
    end
  end
  
  describe '#mouse_clicked_save_button' do
    let(:app) { AutoTaskArrangement.new }
    let(:mock_metrics) { double('PrometheusMetrics') }
    
    before do
      app.instance_variable_set(:@metrics, mock_metrics)
      allow(app).to receive(:mouse_x).and_return(650)
      allow(app).to receive(:mouse_y).and_return(925)
      allow(app).to receive(:button_down?).and_return(true)
    end
    
    it 'tracks button clicks' do
      expect(mock_metrics).to receive(:track_button_click).with('save')
      app.mouse_clicked_save_button
    end
  end
end