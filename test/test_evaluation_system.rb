# Load the Minitest framework and automatically run tests when file is executed
require 'minitest/autorun'
# Load the EvaluationSystem.rb file from the parent directory to access Performance class and rate_performance method
require_relative '../EvaluationSystem.rb'

# Define a test class that inherits from Minitest::Test to group related evaluation system tests
class TestEvaluationSystem < Minitest::Test
  # Setup method runs before each individual test to prepare test data
  def setup
    # Create mock classes for testing
    # Create a simple mock class using Struct that mimics the Classification class structure
    # This avoids dependency on the actual Classification class and focuses testing on EvaluationSystem
    @Classification = Struct.new(:description_arranged, :is_checked)
    
    # Create sample data
    # Create an array of 4 total tasks, all marked as incomplete (is_checked: false)
    @all_tasks = [
      @Classification.new("Task 1", false),  # Task 1 - not completed
      @Classification.new("Task 2", false),  # Task 2 - not completed  
      @Classification.new("Task 3", false),  # Task 3 - not completed
      @Classification.new("Task 4", false)   # Task 4 - not completed
    ]
    # Create an array of 2 completed tasks (representing user's actual completed tasks)
    @completed_tasks = [
      @Classification.new("Task 1", true),   # Task 1 - completed
      @Classification.new("Task 3", true)    # Task 3 - completed
    ]
  end

  # Test that rate_performance function returns a Performance object (correct data type)
  def test_rate_performance_returns_performance_object
    # Call the rate_performance function with test data
    performance = rate_performance(@all_tasks, @completed_tasks)
    # Assert that the returned object is an instance of the Performance class
    assert_kind_of Performance, performance, "Should return a Performance object"
  end

  # Test that rate_performance correctly counts the total number of tasks
  def test_rate_performance_calculates_correct_total
    # Call the rate_performance function
    performance = rate_performance(@all_tasks, @completed_tasks)
    # Assert that total property equals 4 (the length of @all_tasks array)
    assert_equal 4, performance.total, "Total tasks should be 4"
  end
  
  # Test that rate_performance correctly counts the number of completed tasks
  def test_rate_performance_calculates_correct_completed
    # Call the rate_performance function
    performance = rate_performance(@all_tasks, @completed_tasks)
    # Assert that completed property equals 2 (the length of @completed_tasks array)
    assert_equal 2, performance.completed, "Completed tasks should be 2"
  end
  
  # Test that rate_performance correctly calculates completion percentage
  def test_rate_performance_calculates_correct_percentage
    # Call the rate_performance function
    performance = rate_performance(@all_tasks, @completed_tasks)
    # Assert that percentage equals 50.0% (2 completed out of 4 total = 50%)
    assert_equal 50.0, performance.percentage, "Percentage should be 50.0%"
  end
  
  # Test edge case: rate_performance handles empty arrays without crashing
  def test_rate_performance_handles_zero_tasks
    # Call rate_performance with empty arrays (no tasks at all)
    performance = rate_performance([], [])
    # Assert that total tasks is 0 when no tasks provided
    assert_equal 0, performance.total, "Total tasks should be 0"
    # Assert that completed tasks is 0 when no tasks provided
    assert_equal 0, performance.completed, "Completed tasks should be 0"
  end
end