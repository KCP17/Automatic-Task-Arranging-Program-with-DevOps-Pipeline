# Load the class files
require_relative '../ClassificationSystem.rb'
require_relative '../EvaluationSystem.rb'

# Ensure Task class is loaded or defined
if !defined?(Task)
  # Create a simplified Task class if it's not already defined
  class Task
    attr_accessor :description, :type, :deadline, :importance, :difficulty, 
                  :description_arranged, :type_arranged, :deadline_arranged, 
                  :importance_arranged, :difficulty_arranged, :rating, :is_checked
                  
    def initialize(description, type, deadline, importance, difficulty)
      @description = description
      @type = type
      @deadline = deadline
      @importance = importance
      @difficulty = difficulty
      
      # Set arranged values to match original values initially
      @description_arranged = description
      @type_arranged = type
      @deadline_arranged = deadline
      @importance_arranged = importance
      @difficulty_arranged = difficulty
      @rating = 0
      @is_checked = false
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  
  # Display test results
  config.formatter = :documentation
end