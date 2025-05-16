#!/usr/bin/env ruby
# security_fix.rb - Automatically fixes security vulnerabilities in Ruby gems

require 'json'
require 'fileutils'

# Run bundle-audit and get results as JSON
def run_audit
  puts "Running security audit..."
  system("bundle exec bundle-audit check --update --format json > audit_results.json")
  
  if File.exist?('audit_results.json')
    begin
      return JSON.parse(File.read('audit_results.json'))
    rescue JSON::ParserError
      puts "Error: Could not parse audit results"
      return { "vulnerabilities" => [] }
    end
  else
    puts "No audit results found"
    return { "vulnerabilities" => [] }
  end
end

# Fix vulnerable gems
def fix_vulnerabilities(audit_results)
  vulnerabilities = audit_results["vulnerabilities"] || []
  
  if vulnerabilities.empty?
    puts "No vulnerabilities found."
    return false
  end
  
  puts "Found #{vulnerabilities.size} vulnerabilities. Attempting to fix..."
  
  # Backup Gemfile.lock
  if File.exist?('Gemfile.lock')
    FileUtils.cp('Gemfile.lock', 'Gemfile.lock.backup')
  end
  
  # Track if any changes were made
  changes_made = false
  
  # Try to update each vulnerable gem
  vulnerabilities.each do |vuln|
    gem_name = vuln['gem']
    version = vuln['version']
    criticality = vuln['criticality']
    
    puts "Fixing #{gem_name} (#{version}) - Severity: #{criticality}"
    
    # Attempt to update the gem
    update_command = "bundle update #{gem_name} --conservative"
    system(update_command)
    
    # Check if update was successful
    success = $?.success?
    
    if success
      puts "Successfully updated #{gem_name}"
      changes_made = true
    else
      puts "Failed to automatically update #{gem_name}"
    end
  end
  
  # Run bundle-audit again to check if we fixed everything
  puts "Verifying fixes..."
  after_results = run_audit
  remaining = after_results["vulnerabilities"] || []
  
  puts "Results:"
  puts "- Initial vulnerabilities: #{vulnerabilities.size}"
  puts "- Remaining vulnerabilities: #{remaining.size}"
  puts "- Fixed: #{vulnerabilities.size - remaining.size}"
  
  return changes_made
end

# Main function
def main
  audit_results = run_audit
  changes_made = fix_vulnerabilities(audit_results)
  
  if changes_made
    puts "Changes were made to Gemfile.lock"
    exit(0)  # Success with changes
  else
    if audit_results["vulnerabilities"].empty?
      puts "No vulnerabilities to fix"
      exit(0)  # Success with no changes needed
    else
      puts "Could not automatically fix all vulnerabilities"
      exit(1)  # Failure
    end
  end
end

# Run the main function
main