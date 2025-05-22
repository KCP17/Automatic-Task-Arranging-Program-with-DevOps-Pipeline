# Load the Minitest framework and automatically run tests when file is executed
require 'minitest/autorun'
# Load the ClassificationSystem.rb file from the parent directory to access Task and classification classes/methods
require_relative '../ClassificationSystem.rb'
# Define a test class that inherits from Minitest::Test to group related tests together
class TestClassificationSystem < Minitest::Test
  # Setup method runs before each individual test to prepare test data
  def setup
    # Create test tasks
    # Create a high-priority task: study/work type, urgent deadline, very important, hard difficulty
    @task1 = Task.new("Study for exam", "Study/work", "1 day left", "Very important", "Hard")
    # Create a low-priority task: personal type, long deadline, not important, normal difficulty  
    @task2 = Task.new("Watch movie", "Personal", "3 days left", "Not important", "Normal")
    # Create a dataset array with 2 real tasks and 8 nil values (simulating partial task list)
    @data_set = [@task1, @task2, nil, nil, nil, nil, nil, nil, nil, nil]
  end
  
  # Test that the classification function returns an Array data type
  def test_classification_returns_array
    # Call the classification function with our test dataset
    result = classification(@data_set)
    # Assert that the result is an Array, with custom error message if it fails
    assert_kind_of Array, result, "Classification should return an array"
  end
  
  # Test that classification returns the correct number of non-nil tasks
  def test_classification_returns_correct_size
    # Call classification function
    result = classification(@data_set)
    # Assert that result contains exactly 2 elements (ignoring nil tasks)
    assert_equal 2, result.length, "Classification should return array with correct number of tasks"
  end
  
  # Test that classification sorts tasks by priority (highest priority first)
  def test_classification_sorts_by_priority
    # Call classification function  
    result = classification(@data_set)
    # Assert that the study task (higher priority) appears first in the sorted result
    assert_equal "Study for exam", result[0].description_arranged, "Classification should place higher priority tasks first"
  end
  
  # Test that classification assigns numeric rating values to tasks
  def test_classification_sets_rating_values
    # Call classification function
    result = classification(@data_set)
    # Assert that the first task has a numeric rating (Integer or Float)
    assert result[0].rating.is_a?(Numeric), "Task should have a numeric rating"
  end
  
  # Test that classification preserves original task attributes during processing
  def test_classification_preserves_task_attributes
    # Call classification function
    result = classification(@data_set)
    # Assert that task type is preserved in the classification result
    assert_equal "Study/work", result[0].type_arranged, "Classification should preserve task type"
    # Assert that task deadline is preserved in the classification result
    assert_equal "1 day left", result[0].deadline_arranged, "Classification should preserve task deadline"
  end
end