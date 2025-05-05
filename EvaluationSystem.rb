class Accuracy
    attr_accessor :num_of_tasks, :corrects, :percentage
    def initialize(num_of_tasks, corrects, percentage)
      @num_of_tasks, @corrects, @percentage = num_of_tasks, corrects, percentage
    end
end

class Performance
    attr_accessor :total, :completed, :percentage
    def initialize(total, completed, percentage)
      @total, @completed, @percentage = total, completed, percentage
    end
end

def rate_accuracy(prediction, reality)
    if prediction.length == reality.length
        #check number of correct predictions
        num_of_tasks = prediction.length
        puts num_of_tasks if ARGV.length > 0 #debug
        corrects = 0
        num_of_tasks.times do |i|
        corrects += 1 if prediction[i] == reality[i]
        end
        puts "Corrects: #{corrects}" if ARGV.length > 0 #debug
    
        #calculate correct percentage
        percentage = ((corrects.to_f / num_of_tasks.to_f) * 100).round(1)
        puts percentage if ARGV.length > 0 #debug
        
        stats = Accuracy.new(num_of_tasks, corrects, percentage)
        return stats
    else
        stats = "Cannot rate accuracy\ndue to tasks\nnot fully completed"
        return stats
    end
end

def rate_performance(all_tasks, completed_tasks)
    total = all_tasks.length
    completed = completed_tasks.length 
    percentage = ((completed.to_f / total.to_f) * 100).round(1)
    stats = Performance.new(total, completed, percentage)
    return stats
end