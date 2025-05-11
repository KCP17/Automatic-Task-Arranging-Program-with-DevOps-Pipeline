require 'rspec'
require_relative '../ClassificationSystem'

RSpec.describe 'ClassificationSystem' do
  describe '#classification' do
    it 'returns an array of Classification objects' do
      # Create test data
      test_task = Struct.new(:description, :type, :deadline, :importance, :difficulty).new(
        'Test task', 'Study/work', '1 day left', 'Very important', 'Hard'
      )
      data_set = [test_task]
      
      result = classification(data_set)
      
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Classification)
      expect(result.first.rating).to be > 0
    end
    
    it 'sorts tasks by rating from highest to lowest' do
      task1 = Struct.new(:description, :type, :deadline, :importance, :difficulty).new(
        'Low priority', 'Personal', '3 days left', 'Not important', 'Normal'
      )
      task2 = Struct.new(:description, :type, :deadline, :importance, :difficulty).new(
        'High priority', 'Study/work', '1 day left', 'Very important', 'Hard'
      )
      data_set = [task1, task2]
      
      result = classification(data_set)
      
      expect(result[0].rating).to be > result[1].rating
      expect(result[0].description_arranged).to eq('High priority')
    end
  end
end