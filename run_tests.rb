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

# Custom Minitest reporter to count results
module MinitestCounter
  def record(result)
    $minitest_total += 1
    $minitest_passed += 1 if result.passed?
    super
  end
end

# Initialize counters
$minitest_total = 0
$minitest_passed = 0

# Run Minitest with custom reporter
require 'minitest/autorun'

# Patch Minitest reporter to count results
class Minitest::Reporter
  prepend MinitestCounter
end

# Run unit tests
Dir.glob('./test/test_*.rb').each { |file| require file }

# Update counters
minitest_passed = $minitest_passed
minitest_total = $minitest_total

# ----------------- RSPEC INTEGRATION TESTS -----------------

puts "\nRUNNING RSPEC INTEGRATION TESTS\n\n"

# Use RSpec programmatically
require 'rspec'

# Capture RSpec results
class CustomFormatter
  RSpec::Core::Formatters.register self, :example_passed, :example_failed, :example_pending
  
  def initialize(output)
    @output = output
  end
  
  def example_passed(notification)
    $rspec_passed += 1
    $rspec_total += 1
  end
  
  def example_failed(notification)
    $rspec_total += 1
  end
  
  def example_pending(notification)
    # Not counting pending tests in the totals
  end
end

# Initialize counters
$rspec_passed = 0
$rspec_total = 0

# Run RSpec
RSpec.configure do |config|
  config.formatter = 'documentation'
  config.add_formatter CustomFormatter
end

# Run integration specs
RSpec::Core::Runner.run(['./spec/integration'])

# Update counters
rspec_passed = $rspec_passed
rspec_total = $rspec_total

# ----------------- PRINT RESULTS -----------------

puts "\n\nTEST RESULTS SUMMARY\n\n"

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