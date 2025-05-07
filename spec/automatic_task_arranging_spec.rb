require 'rspec'
require_relative '../ClassificationSystem'
require_relative '../EvaluationSystem'

describe 'Task Classification' do
  it 'should classify tasks correctly' do
    # Create a dummy task set
    task = Struct.new(:description, :type, :deadline, :importance, :difficulty)
    data_set = [
      task.new("Task 1", "Study/work", "1 day left", "Very important", "Hard")
    ]
    
    rated_tasks = classification(data_set)
    expect(rated_tasks.length).to eq(1)
    expect(rated_tasks[0].rating).to be > 0
  end
end

describe 'Performance Evaluation' do
  it 'should calculate performance correctly' do
    all_tasks = [1, 2, 3, 4, 5]
    completed_tasks = [1, 2, 3]
    
    performance = rate_performance(all_tasks, completed_tasks)
    expect(performance.percentage).to eq(60.0)
  end
end