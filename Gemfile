source 'https://rubygems.org'

# Main application dependencies with specific version constraints
gem 'gosu', '~> 1.4.6'             # Graphics library
gem 'decisiontree', '~> 0.5.0'      # Decision tree algorithm

# Add iconv to fix compatibility issues
gem 'iconv', '~> 1.0.4'             # Character encoding conversion

group :development, :test do
  # Testing frameworks
  gem 'rspec', '~> 3.13.0'
  gem 'rspec_junit_formatter', '~> 0.6.0'
  gem 'cucumber', '~> 0.7.3'
  gem 'cucumber-json', '~> 0.0.2'
  
  # Code quality tools
  gem 'rubocop', '~> 1.75.5'
  gem 'rubycritic', '~> 4.9.2'
  
  # Security scanning
  gem 'bundler-audit', '~> 0.9.2'
  gem 'brakeman', '~> 7.0.2'
  
  # Build tools
  gem 'rake', '~> 13.2.1'
end