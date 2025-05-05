require 'decisiontree'

class Classification
  attr_accessor :description_arranged, :type_arranged, :deadline_arranged, :importance_arranged, :difficulty_arranged, :rating, :checkbox, :is_checked
  def initialize(description_arranged, type_arranged, deadline_arranged, importance_arranged, difficulty_arranged, rating, checkbox, is_checked)
    @description_arranged, @type_arranged, @deadline_arranged, @importance_arranged, @difficulty_arranged, @rating, @checkbox, @is_checked = description_arranged, type_arranged, deadline_arranged, importance_arranged, difficulty_arranged, rating, checkbox, is_checked
  end
end

def classification(data_set)
  attributes = ['Type', 'Deadline', 'Importance', 'Level of difficulty']
  real_data = [
    ['Study/work', '1 day left', 'Very important', 'Hard', 50],
    ['Study/work', '1 day left', 'Quite important', 'Normal', 50],
    ['Study/work', '2 days left', 'Very important', 'Hard', 50],
    ['Personal', '1 day left', 'Very important', 'Normal', 50],
    ['Study/work', '3 days left', 'Very important', 'Hard', 30],
    ['Personal', '2 days left', 'Quite important', 'Hard', 30],
    ['Study/work', '3 days left', 'Not important', 'Hard', 30],
    ['Study/work', '2 days left', 'Not important', 'Normal', 30],
    ['Personal', '1 day left', 'Quite important', 'Normal', 10],
    ['Personal', '3 days left', 'Quite important', 'Normal', 10],
    ['Personal', '1 day left', 'Not important', 'Normal', 10],
    ['Personal', '3 days left', 'Not important', 'Normal', 10],
  ]

  decision_tree = DecisionTree::ID3Tree.new(attributes, real_data, 1, :discrete)
  decision_tree.train

  count = 0
  data_set.each do |element|
    count += 1 if element != nil
    break if element.nil?
  end

  rated_tasks = Array.new(count)
  #Giving rating to each task
  count.times do |i|
    puts i if ARGV.length > 0 #debug
    set = [data_set[i].type, data_set[i].deadline, data_set[i].importance, data_set[i].difficulty]
    puts set[0], set[1], set[2], set[3] if ARGV.length > 0 #debug
    rating = decision_tree.predict(set)
    puts rating if ARGV.length > 0 #debug
    rated_tasks[i] = Classification.new(data_set[i].description, data_set[i].type, data_set[i].deadline, data_set[i].importance, data_set[i].difficulty, rating, nil, nil)
  end

  #Add extra points to each task
  count.times do |i|
    rated_tasks[i].rating += 1 if rated_tasks[i].type_arranged == 'Personal'
    rated_tasks[i].rating += 2 if rated_tasks[i].type_arranged == 'Study/work'
    rated_tasks[i].rating += 1 if rated_tasks[i].deadline_arranged == '3 days left'
    rated_tasks[i].rating += 2 if rated_tasks[i].deadline_arranged == '2 days left'
    rated_tasks[i].rating += 3 if rated_tasks[i].deadline_arranged == '1 day left'
    rated_tasks[i].rating += 1 if rated_tasks[i].importance_arranged == 'Not important'
    rated_tasks[i].rating += 2 if rated_tasks[i].importance_arranged == 'Quite important'
    rated_tasks[i].rating += 3 if rated_tasks[i].importance_arranged == 'Very important'
    rated_tasks[i].rating += 1 if rated_tasks[i].difficulty_arranged == 'Normal'
    rated_tasks[i].rating += 2 if rated_tasks[i].difficulty_arranged == 'Hard'
  end

  #Bubble-sort algorithm - rearranging from highest to lowest
  count.times do |i|
    for j in 0..(count - 2 - i)
      if rated_tasks[j].rating < rated_tasks[j + 1].rating
          higher_scored = rated_tasks[j + 1]
          rated_tasks[j + 1] = rated_tasks[j]
          rated_tasks[j] = higher_scored
      end
    end
  end
  
  return rated_tasks
end