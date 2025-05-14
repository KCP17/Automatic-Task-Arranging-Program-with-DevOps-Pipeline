require_relative '../spec_helper'

RSpec.describe "Task Management Integration" do
  let(:task1) { Task.new("Study for exam", "Study/work", "1 day left", "Very important", "Hard") }
  let(:task2) { Task.new("Watch movie", "Personal", "3 days left", "Not important", "Normal") }
  let(:task3) { Task.new("Exercise", "Personal", "2 days left", "Quite important", "Hard") }
  let(:data_set) { [task1, task2, task3, nil, nil, nil, nil, nil, nil, nil] }
  
  describe "end-to-end task management flow" do
    it "successfully classifies and evaluates tasks" do
      # Classify tasks
      classified_tasks = classification(data_set)
      
      # Verify classification
      expect(classified_tasks.length).to eq(3)
      expect(classified_tasks[0].description_arranged).to eq("Study for exam")
      
      # Mark some tasks as complete
      classified_tasks[0].is_checked = true
      classified_tasks[2].is_checked = true
      
      # Get completed tasks
      completed_tasks = classified_tasks.select { |task| task.is_checked }
      
      # Evaluate performance
      performance = rate_performance(classified_tasks, completed_tasks)
      
      # Verify performance calculation
      expect(performance.total).to eq(3)
      expect(performance.completed).to eq(2)
      expect(performance.percentage).to be_within(0.1).of(66.7)
    end
    
    it "handles partial task completion" do
      # Classify tasks
      classified_tasks = classification(data_set)
      
      # Complete just one task
      classified_tasks[1].is_checked = true
      
      # Get completed tasks
      completed_tasks = classified_tasks.select { |task| task.is_checked }
      
      # Evaluate performance
      performance = rate_performance(classified_tasks, completed_tasks)
      
      # Verify performance calculation
      expect(performance.total).to eq(3)
      expect(performance.completed).to eq(1)
      expect(performance.percentage).to be_within(0.1).of(33.3)
    end
    
    it "calculates zero percent for no completions" do
      # Classify tasks
      classified_tasks = classification(data_set)
      
      # Complete no tasks
      completed_tasks = []
      
      # Evaluate performance
      performance = rate_performance(classified_tasks, completed_tasks)
      
      # Verify performance calculation
      expect(performance.total).to eq(3)
      expect(performance.completed).to eq(0)
      expect(performance.percentage).to eq(0.0)
    end
  end
end