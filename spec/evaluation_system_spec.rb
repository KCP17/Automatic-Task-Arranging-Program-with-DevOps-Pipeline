require 'rspec'
require_relative '../EvaluationSystem'

RSpec.describe 'EvaluationSystem' do
  describe '#rate_accuracy' do
    it 'calculates accuracy percentage when predictions match reality' do
      Task = Struct.new(:description_arranged)
      prediction = [Task.new('Task 1'), Task.new('Task 2')]
      reality = [Task.new('Task 1'), Task.new('Task 2')]
      
      result = rate_accuracy(prediction, reality)
      
      expect(result).to be_an(Accuracy)
      expect(result.percentage).to eq(100.0)
      expect(result.corrects).to eq(2)
    end
    
    it 'returns error message when arrays have different lengths' do
      prediction = [1, 2, 3]
      reality = [1, 2]
      
      result = rate_accuracy(prediction, reality)
      
      expect(result).to be_a(String)
      expect(result).to include("Cannot rate accuracy")
    end
  end
  
  describe '#rate_performance' do
    it 'calculates performance percentage' do
      all_tasks = [1, 2, 3, 4, 5]
      completed_tasks = [1, 2, 3]
      
      result = rate_performance(all_tasks, completed_tasks)
      
      expect(result).to be_a(Performance)
      expect(result.percentage).to eq(60.0)
      expect(result.completed).to eq(3)
      expect(result.total).to eq(5)
    end
  end
end