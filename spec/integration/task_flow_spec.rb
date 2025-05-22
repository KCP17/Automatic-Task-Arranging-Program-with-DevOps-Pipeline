# Load the spec_helper.rb file which contains RSpec configuration and dependencies
require_relative '../spec_helper'

# Define a test suite for testing the complete task management workflow from start to finish
RSpec.describe "Task Management Integration" do
  # Create reusable test data using RSpec's 'let' method (lazy-loaded, created only when needed)
  # Define a high-priority task: study/work type, urgent deadline, very important, hard difficulty
  let(:task1) { Task.new("Study for exam", "Study/work", "1 day left", "Very important", "Hard") }
  # Define a low-priority task: personal type, long deadline, not important, normal difficulty
  let(:task2) { Task.new("Watch movie", "Personal", "3 days left", "Not important", "Normal") }
  # Define a medium-priority task: personal type, medium deadline, quite important, hard difficulty
  let(:task3) { Task.new("Exercise", "Personal", "2 days left", "Quite important", "Hard") }
  # Create a dataset array with 3 real tasks and 7 nil values (simulating a 10-slot task array)
  let(:data_set) { [task1, task2, task3, nil, nil, nil, nil, nil, nil, nil] }
  
  # Group related tests that test the complete end-to-end workflow
  describe "end-to-end task management flow" do
    # Test the complete workflow: classification → task completion → performance evaluation
    it "successfully classifies and evaluates tasks" do
      # Classify tasks
      # Run the classification algorithm to sort tasks by priority and assign ratings
      classified_tasks = classification(data_set)
      
      # Verify classification
      # Assert that exactly 3 tasks were processed (ignoring nil values)
      expect(classified_tasks.length).to eq(3)
      # Assert that the highest priority task (study exam) is ranked first
      expect(classified_tasks[0].description_arranged).to eq("Study for exam")
      
      # Mark some tasks as complete
      # Simulate user completing the first task (highest priority)
      classified_tasks[0].is_checked = true
      # Simulate user completing the third task (medium priority)
      classified_tasks[2].is_checked = true
      
      # Get completed tasks
      # Filter the classified tasks to get only the ones marked as completed
      completed_tasks = classified_tasks.select { |task| task.is_checked }
      
      # Evaluate performance
      # Calculate performance metrics based on total vs completed tasks
      performance = rate_performance(classified_tasks, completed_tasks)
      
      # Verify performance calculation
      # Assert that total tasks count is correct
      expect(performance.total).to eq(3)
      # Assert that completed tasks count is correct (2 out of 3 tasks completed)
      expect(performance.completed).to eq(2)
      # Assert that percentage is approximately 66.7% (2/3 * 100, allowing for rounding)
      expect(performance.percentage).to be_within(0.1).of(66.7)
    end
    
    # Test partial completion scenario (only some tasks completed)
    it "handles partial task completion" do
      # Classify tasks
      # Run the classification algorithm on the task dataset
      classified_tasks = classification(data_set)
      
      # Complete just one task
      # Simulate user completing only the second task in the ranked list
      classified_tasks[1].is_checked = true
      
      # Get completed tasks
      # Filter to get only the completed tasks (should be just 1)
      completed_tasks = classified_tasks.select { |task| task.is_checked }
      
      # Evaluate performance
      # Calculate performance metrics for partial completion
      performance = rate_performance(classified_tasks, completed_tasks)
      
      # Verify performance calculation
      # Assert total tasks is still 3
      expect(performance.total).to eq(3)
      # Assert only 1 task was completed
      expect(performance.completed).to eq(1)
      # Assert percentage is approximately 33.3% (1/3 * 100)
      expect(performance.percentage).to be_within(0.1).of(33.3)
    end
    
    # Test edge case: no tasks completed at all
    it "calculates zero percent for no completions" do
      # Classify tasks
      # Run classification algorithm normally
      classified_tasks = classification(data_set)
      
      # Complete no tasks
      # Create empty array to represent no completed tasks
      completed_tasks = []
      
      # Evaluate performance
      # Calculate performance when no tasks are completed
      performance = rate_performance(classified_tasks, completed_tasks)
      
      # Verify performance calculation
      # Assert total tasks is still 3 (tasks exist but weren't completed)
      expect(performance.total).to eq(3)
      # Assert zero tasks were completed
      expect(performance.completed).to eq(0)
      # Assert percentage is exactly 0.0% (0/3 * 100)
      expect(performance.percentage).to eq(0.0)
    end
  end
end