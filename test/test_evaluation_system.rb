require 'minitest/autorun'
require_relative '../EvaluationSystem.rb'

class TestEvaluationSystem < Minitest::Test
  def setup
    # Create mock classes for testing
    @Classification = Struct.new(:description_arranged, :is_checked)
    
    # Create sample data
    @all_tasks = [
      @Classification.new("Task 1", false),
      @Classification.new("Task 2", false),
      @Classification.new("Task 3", false),
      @Classification.new("Task 4", false)
    ]
    
    @completed_tasks = [
      @Classification.new("Task 1", true),
      @Classification.new("Task 3", true)
    ]
  end

  def test_rate_performance_returns_performance_object
    performance = rate_performance(@all_tasks, @completed_tasks)
    assert_kind_of Performance, performance, "Should return a Performance object"
  end

  def test_rate_performance_calculates_correct_total
    performance = rate_performance(@all_tasks, @completed_tasks)
    assert_equal 4, performance.total, "Total tasks should be 4"
  end
  
  def test_rate_performance_calculates_correct_completed
    performance = rate_performance(@all_tasks, @completed_tasks)
    assert_equal 2, performance.completed, "Completed tasks should be 2"
  end
  
  def test_rate_performance_calculates_correct_percentage
    performance = rate_performance(@all_tasks, @completed_tasks)
    assert_equal 50.0, performance.percentage, "Percentage should be 50.0%"
  end
  
  def test_rate_performance_handles_zero_tasks
    performance = rate_performance([], [])
    assert_equal 0, performance.total, "Total tasks should be 0"
    assert_equal 0, performance.completed, "Completed tasks should be 0"
  end
end