#!/usr/bin/env ruby

# Test runner with 90% pass/fail gating
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

# Use a more verbose reporter for Minitest
require 'minitest/autorun'

# Create a custom reporter that shows expected vs actual
module Minitest
  module Reporters
    class DetailedReporter < Minitest::AbstractReporter
      def initialize
        super
      end
      
      def record(result)
        puts "Test: #{result.name}"
        puts "  Location: #{result.source_location.join(':')}"
        
        if result.passed?
          puts "  Result: PASS"
        else
          puts "  Result: FAIL"
          puts "  Expected: #{result.expected}"
          puts "  Actual: #{result.actual}"
          puts "  Error Message: #{result.failure.message}"
        end
        puts ""
        
        # Update counters
        if result.name.to_s.include?("test_")
          $minitest_total += 1
          $minitest_passed += 1 if result.passed?
        end
      end
    end
  end
end

# Initialize counters
$minitest_total = 0
$minitest_passed = 0

# Configure Minitest to use our custom reporter
module Minitest
  def self.plugin_detailed_reporter_init(options)
    self.reporter << Minitest::Reporters::DetailedReporter.new
  end
end
Minitest.extensions << 'detailed_reporter'

# Explicitly list the unit test files
puts "Looking for unit tests in: #{Dir.pwd}/test/*.rb"
unit_test_files = Dir.glob('./test/test_*.rb')
puts "Found unit test files: #{unit_test_files.inspect}"

if unit_test_files.empty?
  puts "WARNING: No unit test files found! Check the test directory structure."
else
  # Run unit tests
  unit_test_files.each do |file|
    puts "Loading test file: #{file}"
    require file
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
    @output.puts "  Expected: #{notification.example.exception.expected}" if notification.example.exception.respond_to?(:expected)
    @output.puts "  Actual: #{notification.example.exception.actual}" if notification.example.exception.respond_to?(:actual)
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

puts "\nPASS/FAIL GATING EVALUATION (90% THRESHOLD)\n"

# Check if pass rates meet the 90% threshold
unit_tests_passed_gate = unit_pass_percentage >= 90
integration_tests_passed_gate = integration_pass_percentage >= 90
all_gates_passed = unit_tests_passed_gate && integration_tests_passed_gate

# Display gate status
puts "\nUnit Tests Gate (90% threshold): #{unit_tests_passed_gate ? 'PASSED' : 'FAILED'} (#{unit_pass_percentage.round(1)}%)"
puts "Integration Tests Gate (90% threshold): #{integration_tests_passed_gate ? 'PASSED' : 'FAILED'} (#{integration_pass_percentage.round(1)}%)"
puts "\nOverall Gate Status: #{all_gates_passed ? 'PASSED' : 'FAILED'}"

# Exit with appropriate code for Jenkins
exit(all_gates_passed ? 0 : 1)