Gem::Specification.new do |s|
    s.name        = 'automatic_task_arranging'
    s.version     = '0.1.0'
    s.date        = '2025-05-07'
    s.summary     = "Automatic Task Arranging"
    s.description = "A program to automatically arrange tasks based on priority"
    s.authors     = ["Your Name"]
    s.email       = 'your.email@example.com'
    s.files       = ["AutomaticTaskArranging.rb", 
                     "ClassificationSystem.rb", 
                     "EvaluationSystem.rb", 
                     "TextInput.rb"]
    s.homepage    = 'https://github.com/yourusername/AutomaticTaskArranging'
    s.license     = 'MIT'
    s.add_dependency 'gosu'
    s.add_dependency 'decisiontree'
  end