#!/usr/bin/env ruby

# Test runner with 100% pass/fail gating
# Minitest for unit tests, RSpec for integration tests

puts "\nSTARTING TEST SUITE\n"
puts "Using Minitest for unit tests and RSpec for integration tests\n\n"

# Track test results
minitest_passed = 0
minitest_total = 0
rspec_passed = 0
rspec_total = 0

# ----------------- MINITEST UNIT TESTS -----------------

puts "\nRUNNING MINITEST UNIT TESTS\n\n"

# Customize Minitest output
require 'minitest/autorun'

# Create a custom reporter that shows expected vs actual
class DetailedReporter < Minitest::Reporter
  def record(result)
    puts "Test: #{result.name}"
    
    if result.passed?
      puts "  Result: PASS"
    elsif result.skipped?
      puts "  Result: SKIPPED"
      puts "  Reason: #{result.failure.message}"
    else
      puts "  Result: FAIL"
      puts "  Error Message: #{result.failure.message}"
      puts "  Location: #{result.failure.location}"
      
      # Try to extract expected/actual values
      if result.failure.message =~ /Expected: (.+)\n\s+Actual: (.+)/m
        puts "  Expected: #{$1}"
        puts "  Actual: #{$2}"
      end
    end
    puts ""
    
    # Update counters
    if result.name.to_s.include?("test_")
      $minitest_total += 1
      $minitest_passed += 1 if result.passed?
    end
    
    super
  end
end

# Initialize counters
$minitest_total = 0
$minitest_passed = 0

# Explicitly list the unit test files
puts "Looking for unit tests in: #{Dir.pwd}/test/*.rb"
unit_test_files = Dir.glob('./test/test_*.rb')
puts "Found unit test files: #{unit_test_files.inspect}"

if unit_test_files.empty?
  puts "WARNING: No unit test files found! Check the test directory structure."
else
  # Load the test files but don't run them yet
  unit_test_files.each do |file|
    puts "Loading test file: #{file}"
    require file
  end
  
  # Now explicitly run the Minitest tests
  reporter = DetailedReporter.new
  
  # Get all test suites
  test_suites = ObjectSpace.each_object(Class).select { |klass| klass < Minitest::Test }
  puts "Found test suites: #{test_suites.map(&:name).inspect}"
  
  # Run each test suite
  test_suites.each do |suite|
    puts "Running test suite: #{suite.name}"
    # Get all test methods (they start with "test_")
    test_methods = suite.public_instance_methods(false).grep(/^test_/)
    puts "  Found test methods: #{test_methods.inspect}"
    
    test_methods.each do |method|
      puts "  Running test: #{method}"
      test = suite.new(method)
      result = test.run
      reporter.record(result)
    end
  end
end

# Update counters
minitest_passed = $minitest_passed
minitest_total = $minitest_total

# ----------------- RSPEC INTEGRATION TESTS -----------------

puts "\nRUNNING RSPEC INTEGRATION TESTS\n\n"

# Use RSpec programmatically with detailed output
require 'rspec'

# Capture RSpec results and display detailed info
class DetailedFormatter
  RSpec::Core::Formatters.register self, :example_started, :example_passed, :example_failed, :example_pending
  
  def initialize(output)
    @output = output
  end
  
  def example_started(notification)
    @output.puts "Test: #{notification.example.full_description}"
  end
  
  def example_passed(notification)
    @output.puts "  Result: PASS"
    @output.puts ""
    $rspec_passed += 1
    $rspec_total += 1
  end
  
  def example_failed(notification)
    @output.puts "  Result: FAIL"
    if notification.example.exception.respond_to?(:expected)
      @output.puts "  Expected: #{notification.example.exception.expected}"
      @output.puts "  Actual: #{notification.example.exception.actual}"
    end
    @output.puts "  Error Message: #{notification.example.exception.message}"
    @output.puts ""
    $rspec_total += 1
  end
  
  def example_pending(notification)
    @output.puts "  Result: PENDING"
    @output.puts "  Reason: #{notification.example.execution_result.pending_message}"
    @output.puts ""
  end
end

# Initialize counters
$rspec_passed = 0
$rspec_total = 0

# Run RSpec with our detailed formatter
RSpec.configure do |config|
  # Use both the standard documentation formatter and our detailed formatter
  config.formatter = 'documentation'
  config.add_formatter DetailedFormatter, $stdout
end

# Check for integration test files
integration_test_files = Dir.glob('./spec/integration/*_spec.rb')
puts "Found integration test files: #{integration_test_files.inspect}"

if integration_test_files.empty?
  puts "WARNING: No integration test files found! Check the spec directory structure."
else
  # Run integration specs
  RSpec::Core::Runner.run(['./spec/integration'])
end

# Update counters
rspec_passed = $rspec_passed
rspec_total = $rspec_total

# ----------------- PRINT RESULTS -----------------

puts "\nTEST RESULTS SUMMARY\n\n"

# Calculate pass percentages
unit_pass_percentage = minitest_total > 0 ? (minitest_passed.to_f / minitest_total) * 100 : 0
integration_pass_percentage = rspec_total > 0 ? (rspec_passed.to_f / rspec_total) * 100 : 0

# Format results table
puts "+---------------------------------------+------------+--------+-----------+"
puts "| Test Category                         | Passed     | Total  | Pass Rate |"
puts "+---------------------------------------+------------+--------+-----------+"
puts "| Unit Tests (Minitest)                 | #{minitest_passed.to_s.ljust(10)} | #{minitest_total.to_s.ljust(6)} | #{unit_pass_percentage.round(1).to_s.ljust(9)} % |"
puts "| Integration Tests (RSpec)             | #{rspec_passed.to_s.ljust(10)} | #{rspec_total.to_s.ljust(6)} | #{integration_pass_percentage.round(1).to_s.ljust(9)} % |"
puts "+---------------------------------------+------------+--------+-----------+"

# ----------------- PASS/FAIL GATING -----------------

puts "\nPASS/FAIL GATING EVALUATION (100% THRESHOLD)\n"

# Check if pass rates meet the 100% threshold
unit_tests_passed_gate = unit_pass_percentage == 100
integration_tests_passed_gate = integration_pass_percentage == 100
all_gates_passed = unit_tests_passed_gate && integration_tests_passed_gate

# Display gate status
puts "\nUnit Tests Gate (100% threshold): #{unit_tests_passed_gate ? 'PASSED' : 'FAILED'} (#{unit_pass_percentage.round(1)}%)"
puts "Integration Tests Gate (100% threshold): #{integration_tests_passed_gate ? 'PASSED' : 'FAILED'} (#{integration_pass_percentage.round(1)}%)"
puts "\nOverall Gate Status: #{all_gates_passed ? 'PASSED' : 'FAILED'}"

# Exit with appropriate code for Jenkins
exit(all_gates_passed ? 0 : 1)