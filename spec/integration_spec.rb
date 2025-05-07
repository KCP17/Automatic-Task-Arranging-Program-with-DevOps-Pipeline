require 'rspec'
require_relative '../ClassificationSystem'
require_relative '../EvaluationSystem'

describe 'Integration between Classification and Evaluation', :integration do
  it 'correctly evaluates classified tasks' do
    # Create a dummy task set
    task = Struct.new(:description, :type, :deadline, :importance, :difficulty)
    data_set = [
      task.new("Task 1", "Study/work", "1 day left", "Very important", "Hard")
    ]
    
    # Use the Classification System
    classified_tasks = classification(data_set)
    
    # Now use the Evaluation System on the classification results
    completed_tasks = [classified_tasks[0]]
    performance = rate_performance(classified_tasks, completed_tasks)
    
    # Verify the integration works correctly
    expect(performance).to be_a(Performance)
    expect(performance.total).to eq(1)
    expect(performance.completed).to eq(1)
    expect(performance.percentage).to eq(100.0)
  end
end