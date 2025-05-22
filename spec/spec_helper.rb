# Load the class files
# Import the ClassificationSystem.rb file to access classification functions and Classification class
require_relative '../ClassificationSystem.rb'
# Import the EvaluationSystem.rb file to access evaluation functions and Performance/Accuracy classes
require_relative '../EvaluationSystem.rb'

# Ensure Task class is loaded or defined
# Check if the Task class has already been defined elsewhere in the codebase
if !defined?(Task)
  # Create a simplified Task class if it's not already defined
  # Define a simplified Task class specifically for testing purposes
  class Task
    # Define getter and setter methods for all task attributes used in tests
    attr_accessor :description, :type, :deadline, :importance, :difficulty, 
                  :description_arranged, :type_arranged, :deadline_arranged, 
                  :importance_arranged, :difficulty_arranged, :rating, :is_checked
                  
    # Constructor method that creates a new Task object with required parameters
    def initialize(description, type, deadline, importance, difficulty)
      # Store the original task description (e.g., "Study for exam")
      @description = description
      # Store the task type (e.g., "Study/work" or "Personal")
      @type = type
      # Store the task deadline (e.g., "1 day left", "3 days left")
      @deadline = deadline
      # Store the task importance level (e.g., "Very important", "Not important")
      @importance = importance
      # Store the task difficulty level (e.g., "Hard", "Normal")
      @difficulty = difficulty
      # Set arranged values to match original values initially
      # Initialize arranged description (used after classification processing)
      @description_arranged = description
      # Initialize arranged type (used after classification processing)
      @type_arranged = type
      # Initialize arranged deadline (used after classification processing)
      @deadline_arranged = deadline
      # Initialize arranged importance (used after classification processing)
      @importance_arranged = importance
      # Initialize arranged difficulty (used after classification processing)
      @difficulty_arranged = difficulty
      # Initialize rating to 0 (will be calculated by classification algorithm)
      @rating = 0
      # Initialize checked status to false (task not completed yet)
      @is_checked = false
    end
  end
end

# Configure RSpec testing framework with specific settings
RSpec.configure do |config|
  # Configure expectation settings for RSpec assertions
  config.expect_with :rspec do |expectations|
    # Enable chain clauses in custom matcher descriptions for better error messages
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Configure mock/stub settings for RSpec test doubles
  config.mock_with :rspec do |mocks|
    # Enable verification of partial doubles to catch method name typos
    mocks.verify_partial_doubles = true
  end

  # Set shared context metadata behavior to apply to host groups
  config.shared_context_metadata_behavior = :apply_to_host_groups
  # Display test results
  # Set the output formatter to documentation style (shows test names and descriptions)
  config.formatter = :documentation
end