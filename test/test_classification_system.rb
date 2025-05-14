require 'minitest/autorun'
require_relative '../ClassificationSystem.rb'

class TestClassificationSystem < Minitest::Test
  def setup
    # Create test tasks
    @task1 = Task.new("Study for exam", "Study/work", "1 day left", "Very important", "Hard")
    @task2 = Task.new("Watch movie", "Personal", "3 days left", "Not important", "Normal")
    @data_set = [@task1, @task2, nil, nil, nil, nil, nil, nil, nil, nil]
  end
  
  def test_classification_returns_array
    result = classification(@data_set)
    assert_kind_of Array, result, "Classification should return an array"
  end
  
  def test_classification_returns_correct_size
    result = classification(@data_set)
    assert_equal 2, result.length, "Classification should return array with correct number of tasks"
  end
  
  def test_classification_sorts_by_priority
    result = classification(@data_set)
    assert_equal "Study for exam", result[0].description_arranged, "Classification should place higher priority tasks first"
  end
  
  def test_classification_sets_rating_values
    result = classification(@data_set)
    assert result[0].rating.is_a?(Numeric), "Task should have a numeric rating"
  end
  
  def test_classification_preserves_task_attributes
    result = classification(@data_set)
    assert_equal "Study/work", result[0].type_arranged, "Classification should preserve task type"
    assert_equal "1 day left", result[0].deadline_arranged, "Classification should preserve task deadline"
  end
end