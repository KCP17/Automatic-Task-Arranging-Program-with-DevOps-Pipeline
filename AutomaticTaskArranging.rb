require 'rubygems'
require 'gosu'
require './TextInput'
require './ClassificationSystem'
require './EvaluationSystem'
require './prometheus_metrics'

module ZOrder
    BACKGROUND, LAYER_1, LAYER_2, LAYER_3, LAYER_4 = *0..4
end


class Checkbox
    attr_accessor :x, :y
    def initialize(x, y)
        @x, @y = x, y
    end
end

class AutoTaskArrangement < Gosu::Window

    SCREEN_WIDTH, SCREEN_HEIGHT = 1920, 1080
    BACKGROUND_COLOR = Gosu::Color::BLACK

    BUTTON_WIDTH, BUTTON_HEIGHT = 150, 75

    SAVE_BUTTON_X, SAVE_BUTTON_Y = 600, 900
    CONFIRM_BUTTON_X, CONFIRM_BUTTON_Y = 1300, 900
    FINISHED_BUTTON_X, FINISHED_BUTTON_Y = 1000, 900
    RETURN_BUTTON_X, RETURN_BUTTON_Y = 1700, 900
    PERF_BUTTON_X, PERF_BUTTON_Y = 1300, 900
    RESET_BUTTON_X, RESET_BUTTON_Y = 200, 900

    #display choices
    CHOICE_WIDTH, CHOICE_HEIGHT = 160, 50

    STUDY_WORK_X, STUDY_WORK_Y = 50, 400
    PERSONAL_X, PERSONAL_Y = 50 + 170*1, 400

    ONEDAY_X, ONEDAY_Y = 50, 500
    TWODAYS_X, TWODAYS_Y = 50 + 170*1, 500
    THREEDAYS_X, THREEDAYS_Y = 50 + 170*2, 500

    VERY_IMPORTANT_X, VERY_IMPORTANT_Y = 50, 600
    QUITE_IMPORTANT_X, QUITE_IMPORTANT_Y = 50 + 170*1, 600
    NOT_IMPORTANT_X, NOT_IMPORTANT_Y = 50 + 170*2, 600

    HARD_X, HARD_Y = 50, 700
    NORMAL_X, NORMAL_Y = 50 + 170*1, 700

    #colors
    DEFAULT_YELLOW = Gosu::Color.rgb(255,196,0)
    DEFAULT_RED = Gosu::Color.rgb(200,0,53)
    DEFAULT_PURPLE = Gosu::Color.rgb(177,72,210)

    def initialize
        super SCREEN_WIDTH, SCREEN_HEIGHT
	    self.caption = "Automatic Task-arranging Program"

		font = Gosu::Font.new(self, 'Baloo-Regular.ttf', 35)
        initial_text = "Task?"
        @text_fields = Array.new(1) { |index| TextField.new(self, font, 55, 300, initial_text) }
        
        @label_text = Gosu::Font.new(self, 'Baloo-Regular.ttf',50)
        @button_font = Gosu::Font.new(self, 'Baloo-Regular.ttf', 30)
        @normal_text = Gosu::Font.new(self, 'Baloo-Regular.ttf', 30)

        @background = Gosu::Image.new('background.jpg')
        @checkmark = Gosu::Image.new('checkmark.png')
        @balloon_chat = Gosu::Image.new('balloon_chat.png')

        #navigation bar
        @menu_icon = Gosu::Image.new('menu_icon.png')
        @home_icon = Gosu::Image.new('home_icon.png')
        @stats_icon = Gosu::Image.new('stats_icon.png')
        @display_menu = false

        @sets = Array.new()
        @sets_of_ranked_tasks = Array.new()
        @sets_of_real_decisions = Array.new()
        @set_index = -1

        @screen_choice = 0

        @number_of_completed_sets = 0
        @overall_performance = []

        # Initialize Prometheus metrics
        @metrics = PrometheusMetrics.new(9090)
        @metrics.track_screen_view('home')
        
	end
    
    # Track when new sets are created
    def display_home_screen
        @label_text.draw_text("WELCOME TO", 725, 200, ZOrder::LAYER_1, 2.0, 2.0, Gosu::Color::WHITE)
        @label_text.draw_text("AUTOMATIC TASK-ARRANGING", 300, 275, ZOrder::LAYER_1, 3.0, 3.0, DEFAULT_YELLOW)
        @label_text.draw_text("PROGRAM", 750, 400, ZOrder::LAYER_1, 2.0, 2.0, Gosu::Color::WHITE)
        
        if (mouse_x > 775 and mouse_x < 775 + 275) and (mouse_y > 800 and mouse_y < 800 + 75)
            button_color, word_color = DEFAULT_RED, DEFAULT_YELLOW
            if button_down?(Gosu::MsLeft)
                #create new set of tasks
                @metrics&.track_button_click('new_set') # for prometheus
                @set_index += 1
                if @set_index < 9
                    @metrics&.track_set_created # for prometheus
                    @sets[@set_index] = Array.new(10)
                    @sets_of_ranked_tasks[@set_index] = nil
                    @sets_of_real_decisions[@set_index] = Array.new()
                    #initialize
                    @save_clicked = true
                    @i = 0
                    @confirm_clicked = false
                    @checked = false #tasks not cheked yet
                    #accuracy & performance not shown initially
                    @showed_acc = false
                    @showed_perf = false
                    #reset attributes
                    @description = nil
                    @study_work_indicator, @personal_indicator = nil, nil
                    @oneday_indicator, @twodays_indicator, @threedays_indicator = nil, nil, nil
                    @veryimportant_indicator, @quiteimportant_indicator, @notimportant_indicator = nil, nil, nil
                    @hard_indicator, @normal_indicator = nil, nil
                    #switch screen
                    @screen_choice = 1
                else
                    @show_warning = true #warning more than 9 tasks, need to reset
                end
            end
        else
            button_color, word_color = DEFAULT_YELLOW, DEFAULT_RED
        end

        #'New task' button
        draw_rect(775, 800, 275, 75, button_color, ZOrder::LAYER_2, mode=:default)
        @button_font.draw_text("CREATE NEW SET", 775+20, 800+15, ZOrder::LAYER_3, 1.5, 1.5, word_color)

        if @show_warning
            @label_text.draw_text("Warning! Exceeded the maximum number of sets\nPlease reset (in STATS screen)", 300, 600, ZOrder::LAYER_1, 1.0, 1.0, Gosu::Color::RED)
        else
            @label_text.draw_text("Instructions:\nPress the button below to create a new set of tasks", 300, 600, ZOrder::LAYER_1, 1.0, 1.0, Gosu::Color::WHITE)
        end
    end

    def draw_save_button
        if mouse_clicked_save_button
            draw_rect(SAVE_BUTTON_X-3, SAVE_BUTTON_Y-3, BUTTON_WIDTH+6, BUTTON_HEIGHT+6, Gosu::Color::WHITE, ZOrder::LAYER_1, mode=:default)
        end
        if (mouse_x > SAVE_BUTTON_X and mouse_x < SAVE_BUTTON_X + BUTTON_WIDTH) and (mouse_y > SAVE_BUTTON_Y and mouse_y < SAVE_BUTTON_Y + BUTTON_HEIGHT)
            draw_rect(SAVE_BUTTON_X, SAVE_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_RED, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("SAVE", SAVE_BUTTON_X+25, SAVE_BUTTON_Y+10, ZOrder::LAYER_3, 2.0, 2.0, DEFAULT_YELLOW)
        else
            draw_rect(SAVE_BUTTON_X, SAVE_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("SAVE", SAVE_BUTTON_X+25, SAVE_BUTTON_Y+10, ZOrder::LAYER_3, 2.0, 2.0, DEFAULT_RED)
        end
    end

    def draw_confirm_button
        if mouse_clicked_confirm_button
            if @sets[@set_index][0].nil?
                @no_task_warning = true
            else
                @screen_choice = 2
            end
        end
        if @no_task_warning and !@duplicate_warning
            @balloon_chat.draw(1400, 75, ZOrder::LAYER_2, 0.7, 0.7)
            @normal_text.draw_text("Must have\nat least\n1 task", 1450, 120, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
        if (mouse_x > CONFIRM_BUTTON_X and mouse_x < CONFIRM_BUTTON_X + BUTTON_WIDTH) and (mouse_y > CONFIRM_BUTTON_Y and mouse_y < CONFIRM_BUTTON_Y + BUTTON_HEIGHT)
            draw_rect(CONFIRM_BUTTON_X, CONFIRM_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_RED, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("CONFIRM", CONFIRM_BUTTON_X+15, CONFIRM_BUTTON_Y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_YELLOW)
        else
            draw_rect(CONFIRM_BUTTON_X, CONFIRM_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("CONFIRM", CONFIRM_BUTTON_X+15, CONFIRM_BUTTON_Y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
    end

    def display_screen1_title
        @label_text.draw_text("CREATING TASKS", 650, 100, ZOrder::LAYER_1, 2.5, 2.5, DEFAULT_YELLOW)
    end

    def display_labels
        #left-half
        @label_text.draw_text("Your Task:", 50, 250, ZOrder::LAYER_1, 1.0, 1.0, Gosu::Color::WHITE)
        @label_text.draw_text("Type of task:", 50, 350, ZOrder::LAYER_1, 1.0, 1.0, Gosu::Color::WHITE)
        @label_text.draw_text("Deadline:", 50, 450, ZOrder::LAYER_1, 1.0, 1.0, Gosu::Color::WHITE)
        @label_text.draw_text("Importance:", 50, 550, ZOrder::LAYER_1, 1.0, 1.0, Gosu::Color::WHITE)
        @label_text.draw_text("Level of difficulty:", 50, 650, ZOrder::LAYER_1, 1.0, 1.0, Gosu::Color::WHITE)
        #right-half
        @label_text.draw_text("Saved Tasks:", 970, 250, ZOrder::LAYER_1, 1.5, 1.5, DEFAULT_YELLOW)
    end

    def display_choices
        #display study/work choice
        if ((mouse_x > STUDY_WORK_X and mouse_x < STUDY_WORK_X + CHOICE_WIDTH) and (mouse_y > STUDY_WORK_Y and mouse_y < STUDY_WORK_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @study_work_indicator, @personal_indicator = true, false
        end
        if @study_work_indicator
            draw_rect(STUDY_WORK_X, STUDY_WORK_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Study/Work", STUDY_WORK_X+10, STUDY_WORK_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(STUDY_WORK_X, STUDY_WORK_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Study/Work", STUDY_WORK_X+10, STUDY_WORK_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display personal choice
        
        if ((mouse_x > PERSONAL_X and mouse_x < PERSONAL_X + CHOICE_WIDTH) and (mouse_y > PERSONAL_Y and mouse_y < PERSONAL_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @study_work_indicator, @personal_indicator = false, true
        end
        if @personal_indicator
            draw_rect(PERSONAL_X, PERSONAL_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Personal", PERSONAL_X+10, PERSONAL_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(PERSONAL_X, PERSONAL_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Personal", PERSONAL_X+10, PERSONAL_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display 1 DAY choice
        if ((mouse_x > ONEDAY_X and mouse_x < ONEDAY_X + CHOICE_WIDTH) and (mouse_y > ONEDAY_Y and mouse_y < ONEDAY_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @oneday_indicator, @twodays_indicator, @threedays_indicator = true, false, false
        end
        if @oneday_indicator
            draw_rect(ONEDAY_X, ONEDAY_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("1 day left", ONEDAY_X+10, ONEDAY_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(ONEDAY_X, ONEDAY_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("1 day left", ONEDAY_X+10, ONEDAY_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display 2 DAYS choice
        if ((mouse_x > TWODAYS_X and mouse_x < TWODAYS_X + CHOICE_WIDTH) and (mouse_y > TWODAYS_Y and mouse_y < TWODAYS_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @oneday_indicator, @twodays_indicator, @threedays_indicator = false, true, false
        end
        if @twodays_indicator
            draw_rect(TWODAYS_X, TWODAYS_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("2 days left", TWODAYS_X+10, TWODAYS_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(TWODAYS_X, TWODAYS_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("2 days left", TWODAYS_X+10, TWODAYS_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display 3 DAYS choice
        if ((mouse_x > THREEDAYS_X and mouse_x < THREEDAYS_X + CHOICE_WIDTH) and (mouse_y > THREEDAYS_Y and mouse_y < THREEDAYS_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @oneday_indicator, @twodays_indicator, @threedays_indicator = false, false, true
        end
        if @threedays_indicator
            draw_rect(THREEDAYS_X, THREEDAYS_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("3 days left", THREEDAYS_X+10, THREEDAYS_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(THREEDAYS_X, THREEDAYS_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("3 days left", THREEDAYS_X+10, THREEDAYS_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display VERY IMPORTANT choice
        if ((mouse_x > VERY_IMPORTANT_X and mouse_x < VERY_IMPORTANT_X + CHOICE_WIDTH) and (mouse_y > VERY_IMPORTANT_Y and mouse_y < VERY_IMPORTANT_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @veryimportant_indicator, @quiteimportant_indicator, @notimportant_indicator = true, false, false
        end
        if @veryimportant_indicator
            draw_rect(VERY_IMPORTANT_X, VERY_IMPORTANT_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Very important", VERY_IMPORTANT_X+10, VERY_IMPORTANT_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(VERY_IMPORTANT_X, VERY_IMPORTANT_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Very important", VERY_IMPORTANT_X+10, VERY_IMPORTANT_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display QUITE IMPORTANT choice
        if ((mouse_x > QUITE_IMPORTANT_X and mouse_x < QUITE_IMPORTANT_X + CHOICE_WIDTH) and (mouse_y > QUITE_IMPORTANT_Y and mouse_y < QUITE_IMPORTANT_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @veryimportant_indicator, @quiteimportant_indicator, @notimportant_indicator = false, true, false
        end
        if @quiteimportant_indicator
            draw_rect(QUITE_IMPORTANT_X, QUITE_IMPORTANT_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Quite important", QUITE_IMPORTANT_X+10, QUITE_IMPORTANT_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(QUITE_IMPORTANT_X, QUITE_IMPORTANT_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Quite important", QUITE_IMPORTANT_X+10, QUITE_IMPORTANT_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display NOT IMPORTANT choice
        if ((mouse_x > NOT_IMPORTANT_X and mouse_x < NOT_IMPORTANT_X + CHOICE_WIDTH) and (mouse_y > NOT_IMPORTANT_Y and mouse_y < NOT_IMPORTANT_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @veryimportant_indicator, @quiteimportant_indicator, @notimportant_indicator = false, false, true
        end
        if @notimportant_indicator
            draw_rect(NOT_IMPORTANT_X, NOT_IMPORTANT_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Not important", NOT_IMPORTANT_X+10, NOT_IMPORTANT_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(NOT_IMPORTANT_X, NOT_IMPORTANT_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Not important", NOT_IMPORTANT_X+10, NOT_IMPORTANT_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display HARD choice
        if ((mouse_x > HARD_X and mouse_x < HARD_X + CHOICE_WIDTH) and (mouse_y > HARD_Y and mouse_y < HARD_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @hard_indicator, @normal_indicator = true, false
        end
        if @hard_indicator
            draw_rect(HARD_X, HARD_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Hard", HARD_X+10, HARD_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(HARD_X, HARD_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Hard", HARD_X+10, HARD_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

        #display NORMAL choice
        if ((mouse_x > NORMAL_X and mouse_x < NORMAL_X + CHOICE_WIDTH) and (mouse_y > NORMAL_Y and mouse_y < NORMAL_Y + CHOICE_HEIGHT) and button_down?(Gosu::MsLeft))
            @hard_indicator, @normal_indicator = false, true
        end
        if @normal_indicator
            draw_rect(NORMAL_X, NORMAL_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_PURPLE, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Normal", NORMAL_X+10, NORMAL_Y+10, ZOrder::LAYER_3, 1.0, 1.0, Gosu::Color::WHITE)
        else
            draw_rect(NORMAL_X, NORMAL_Y, CHOICE_WIDTH, CHOICE_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("Normal", NORMAL_X+10, NORMAL_Y+10, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end

    end

    def read_task
        type = 'Study/work' if @study_work_indicator
        type = 'Personal' if @personal_indicator
        deadline = '1 day left' if @oneday_indicator
        deadline = '2 days left' if @twodays_indicator
        deadline = '3 days left' if @threedays_indicator
        importance = 'Very important' if @veryimportant_indicator
        importance = 'Quite important' if @quiteimportant_indicator
        importance = 'Not important' if @notimportant_indicator
        difficulty = 'Hard' if @hard_indicator
        difficulty = 'Normal' if @normal_indicator
        task = Task.new(@description, type, deadline, importance, difficulty)
        return task
    end
    
    def read_tasks
        if mouse_clicked_save_button and @i < 10
            if @i >= 1
                for i in 1..@i
                    cannot_save = 'duplicate' if @sets[@set_index][i-1].description == @description
                end
            end
            cannot_save = 'no duplicate' if cannot_save != 'duplicate'
            cannot_save = 'not_enough_attributes' if !((@study_work_indicator || @personal_indicator) && (@oneday_indicator || @twodays_indicator || @threedays_indicator) && (@veryimportant_indicator || @quiteimportant_indicator || @notimportant_indicator) && (@hard_indicator || @normal_indicator))
            @duplicate_warning = (cannot_save == 'duplicate') ? true : false
            @not_entered_warning = (@description.nil?) ? true : false
            @not_enough_attributes_warning = (cannot_save == 'not_enough_attributes') ? true : false
            @save_clicked = false if (cannot_save != 'duplicate' and cannot_save != 'not_enough_attributes' and @description != nil) else true
                    
            if !@save_clicked
                @sets[@set_index][@i] = read_task
                @save_clicked = true
                @i += 1
            end
        end
        if @duplicate_warning
            @balloon_chat.draw(1400, 75, ZOrder::LAYER_2, 0.7, 0.7)
            @normal_text.draw_text("Watch out\nduplicates", 1450, 150, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
        if @not_entered_warning
            @balloon_chat.draw(50, 20, ZOrder::LAYER_2, 0.7, 0.7)
            @normal_text.draw_text("Must press\n'ENTER'", 100, 90, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
        if @not_enough_attributes_warning
            @balloon_chat.draw(400, 250, ZOrder::LAYER_2, 0.7, 0.7)
            @normal_text.draw_text("Not enough\nattributes", 450, 325, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
    end

    def display_saved_tasks
        @saved = true if mouse_clicked_save_button
        if @sets[@set_index][0].nil?
            @normal_text.draw_text("*Enter your task, and press the 'ENTER' key\nThen select your task's attributes\nThen click 'SAVE'\n**You cannot have duplicate tasks (with the same name)\nWhen you're done, click 'CONFIRM'", 950, 400, ZOrder::LAYER_2, 1.7, 1.7, Gosu::Color::WHITE)
        end
        if @saved
            index = -10
            while index <= -1
                x, y = 970, 320 + 55*(@i+index)
                if !@sets[@set_index][@i+index].nil?
                    @normal_text.draw_text("#{@i+index+1}. #{@sets[@set_index][@i+index].description}", x, y, ZOrder::LAYER_2, 1.7, 1.7, Gosu::Color::WHITE)
                end
                if (mouse_x > x && mouse_x < x+700) and (mouse_y > y+5 && mouse_y < y+30)
                    draw_rect(mouse_x, mouse_y, 300, 200, Gosu::Color::WHITE, ZOrder::LAYER_3, mode=:default) if !@sets[@set_index][@i+index].nil?
                    @normal_text.draw_text("Type: #{@sets[@set_index][@i+index].type}", mouse_x+10, mouse_y+10, ZOrder::LAYER_4, 1.0, 1.0, Gosu::Color::BLACK) if !@sets[@set_index][@i+index].nil?
                    @normal_text.draw_text("Deadline: #{@sets[@set_index][@i+index].deadline}", mouse_x+10, mouse_y+40, ZOrder::LAYER_4, 1.0, 1.0, Gosu::Color::BLACK) if !@sets[@set_index][@i+index].nil?
                    @normal_text.draw_text("Importance: #{@sets[@set_index][@i+index].importance}", mouse_x+10, mouse_y+70, ZOrder::LAYER_4, 1.0, 1.0, Gosu::Color::BLACK) if !@sets[@set_index][@i+index].nil?
                    @normal_text.draw_text("Difficulty: #{@sets[@set_index][@i+index].difficulty}", mouse_x+10, mouse_y+100, ZOrder::LAYER_4, 1.0, 1.0, Gosu::Color::BLACK) if !@sets[@set_index][@i+index].nil?
                end
                index += 1
            end
        end
    end

    def display_screen_1
        display_screen1_title
        @text_fields.each { |tf| tf.draw }
        draw_save_button
        draw_confirm_button
        display_labels
        display_choices
        read_tasks
        display_saved_tasks
    end

    def click_on_checkbox(checkbox)
        if ((mouse_x > checkbox.x && mouse_x < checkbox.x+40) and (mouse_y > checkbox.y && mouse_y < checkbox.y+40) and button_down?(Gosu::MsLeft))
            return true
        else
            return false
        end
    end

    def recheck(task, checked, count)
        if checked and task.is_checked != true
            @sets_of_real_decisions[@set_index] << task
            if ARGV.length > 0 #debug
                puts @sets_of_real_decisions[@set_index][0].description_arranged
                puts @sets_of_real_decisions[@set_index][1].description_arranged if !@sets_of_real_decisions[@set_index][1].nil?
                puts @sets_of_real_decisions[@set_index][2].description_arranged if !@sets_of_real_decisions[@set_index][2].nil?
            end
        end

    end

    def display_arranged_task(i, count)
        x, y = 300, 250 + 60*i
        checkbox_x, checkbox_y = x + 900, y + 7
        @normal_text.draw_text("#{i+1}. #{@sets_of_ranked_tasks[@set_index][i].description_arranged} - #{@sets_of_ranked_tasks[@set_index][i].rating}", x, y, ZOrder::LAYER_2, 2.0, 2.0, Gosu::Color::WHITE)
        draw_rect(checkbox_x, checkbox_y, 40, 40, Gosu::Color::WHITE, ZOrder::LAYER_2, mode=:default) #draw blank checkboxes
        
        @sets_of_ranked_tasks[@set_index][i].checkbox = Checkbox.new(checkbox_x, checkbox_y)
        checkbox_checked = click_on_checkbox(@sets_of_ranked_tasks[@set_index][i].checkbox)
        
        recheck(@sets_of_ranked_tasks[@set_index][i], checkbox_checked, count)

        if checkbox_checked
            @sets_of_ranked_tasks[@set_index][i].is_checked = true
        end
        if @sets_of_ranked_tasks[@set_index][i].is_checked
            @checkmark.draw(checkbox_x+4, checkbox_y+4, ZOrder::LAYER_3, 0.04, 0.04)
        end

    end

    # Track task arrangement timing
    def display_arranged_tasks
        if mouse_clicked_confirm_button and !@confirm_clicked
            @metrics&.track_task_arrangement_time do
                @sets_of_ranked_tasks[@set_index] = classification(@sets[@set_index])
            end
            @count = @sets_of_ranked_tasks[@set_index].length
            @confirm_clicked = true
        end
        @count.times do |i|
            display_arranged_task(i, @count)
        end
    end

    def draw_finished_button
        if ((mouse_x > FINISHED_BUTTON_X and mouse_x < FINISHED_BUTTON_X + BUTTON_WIDTH) and (mouse_y > FINISHED_BUTTON_Y and mouse_y < FINISHED_BUTTON_Y + BUTTON_HEIGHT))
            if button_down?(Gosu::MsLeft)
                @number_of_completed_sets += 1
                @screen_choice = 3
            end
            draw_rect(FINISHED_BUTTON_X, FINISHED_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_RED, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("FINISHED", FINISHED_BUTTON_X+15, FINISHED_BUTTON_Y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_YELLOW)
        else
            draw_rect(FINISHED_BUTTON_X, FINISHED_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("FINISHED", FINISHED_BUTTON_X+15, FINISHED_BUTTON_Y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
    end

    def display_screen2_title
        @label_text.draw_text("ARRANGED TASKS", 625, 100, ZOrder::LAYER_1, 2.5, 2.5, DEFAULT_YELLOW)
    end

    def display_screen_2
        display_screen2_title
        display_arranged_tasks
        draw_finished_button
    end

    def draw_set(i)
        x = 750 + 200*i if i/3 == 0
        x = 750 + 200*(i-3) if i/3 == 1
        x = 750 + 200*(i-6) if i/3 == 2
        y = 250 + 125*(i/3)
        
        if (mouse_x > x and mouse_x < x + BUTTON_WIDTH) and (mouse_y > y and mouse_y < y + BUTTON_HEIGHT)
            if button_down?(Gosu::MsLeft)
                @set_indicator = i
                @showed_acc = false
                @showed_perf = false
                @screen_choice = 4
            end
            draw_rect(x, y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_RED, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("SET #{i+1}", x+15, y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_YELLOW)
        else
            draw_rect(x, y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("SET #{i+1}", x+15, y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
    end

    def draw_sets
        @number_of_completed_sets.times do |i|
            draw_set(i)
        end
    end

    def draw_perf_stats_button
        if (mouse_x > PERF_BUTTON_X and mouse_x < PERF_BUTTON_X + BUTTON_WIDTH+100) and (mouse_y > PERF_BUTTON_Y and mouse_y < PERF_BUTTON_Y + BUTTON_HEIGHT)
            if button_down?(Gosu::MsLeft)
                @showed_perf = false
                @perf_choice = true
                @acc_choice = false
                @screen_choice = 5
            end
            draw_rect(PERF_BUTTON_X, PERF_BUTTON_Y, BUTTON_WIDTH+100, BUTTON_HEIGHT, DEFAULT_RED, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("OVERALL PERFORMANCE", PERF_BUTTON_X+15, PERF_BUTTON_Y+15, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_YELLOW)
        else
            draw_rect(PERF_BUTTON_X, PERF_BUTTON_Y, BUTTON_WIDTH+100, BUTTON_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("OVERALL PERFORMANCE", PERF_BUTTON_X+15, PERF_BUTTON_Y+15, ZOrder::LAYER_3, 1.0, 1.0, DEFAULT_RED)
        end
    end

    def display_screen3_title
        @label_text.draw_text("SAVED SETS", 625, 100, ZOrder::LAYER_1, 2.5, 2.5, DEFAULT_YELLOW)
    end

    def draw_reset_button
        if ((mouse_x > RESET_BUTTON_X and mouse_x < RESET_BUTTON_X + BUTTON_WIDTH) and (mouse_y > RESET_BUTTON_Y and mouse_y < RESET_BUTTON_Y + BUTTON_HEIGHT))
            if button_down?(Gosu::MsLeft)
                @sets = Array.new()
                @sets_of_ranked_tasks = Array.new()
                @sets_of_real_decisions = Array.new()
                @set_index = -1
                @number_of_completed_sets = 0
                @overall_performance = []
                @screen_choice = 0 #back to home screen
            end
            draw_rect(RESET_BUTTON_X, RESET_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_RED, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("RESET", RESET_BUTTON_X+15, RESET_BUTTON_Y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_YELLOW)
        else
            draw_rect(RESET_BUTTON_X, RESET_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("RESET", RESET_BUTTON_X+15, RESET_BUTTON_Y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
    end

    def display_screen_3
        display_screen3_title
        draw_sets
        draw_perf_stats_button
        draw_reset_button
    end

    def show_prediction(set_index)
        @normal_text.draw_text("Prediction:", 100, 225, ZOrder::LAYER_2, 2.0, 2.0, DEFAULT_YELLOW)
        @sets_of_ranked_tasks[set_index].length.times do |i|
            x, y = 100, 300 + 50*i
            @normal_text.draw_text("#{i+1}. #{@sets_of_ranked_tasks[set_index][i].description_arranged}", x, y, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::WHITE)
        end
    end

    def show_reality(set_index)
        @normal_text.draw_text("Reality:", 600, 225, ZOrder::LAYER_2, 2.0, 2.0, DEFAULT_YELLOW)
        @sets_of_real_decisions[set_index].length.times do |i|
            x, y = 600, 300 + 50*i
            @normal_text.draw_text("#{i+1}. #{@sets_of_real_decisions[set_index][i].description_arranged}", x, y, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::WHITE)
        end
    end

    def show_accuracy(set_index)
        if !@showed_acc
            @accuracy = rate_accuracy(@sets_of_ranked_tasks[set_index], @sets_of_real_decisions[set_index])
            @showed_acc = true
        end

        @normal_text.draw_text("Accuracy:", 1600, 225, ZOrder::LAYER_2, 2.0, 2.0, DEFAULT_YELLOW)

        if @sets_of_ranked_tasks[set_index].length != @sets_of_real_decisions[set_index].length
            @normal_text.draw_text(@accuracy, 1600, 300, ZOrder::LAYER_2, 1.0, 1.0, Gosu::Color::WHITE)
        else
            color = Gosu::Color::GREEN if @accuracy.percentage >= 80
            color = Gosu::Color::RED if @accuracy.percentage < 50
            color = Gosu::Color::YELLOW if @accuracy.percentage >= 50 && @accuracy.percentage < 80
            #draw Accuracy chart
            top_y, bottom_y = 300, 750
            acc_width = 150
            acc_height = (@accuracy.percentage / 100) * (bottom_y - top_y)
            acc_x = 1600
            acc_y = bottom_y - acc_height
            #draw border
            draw_line(acc_x, top_y, Gosu::Color::WHITE, acc_x+acc_width, top_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
            draw_line(acc_x, bottom_y, Gosu::Color::WHITE, acc_x+acc_width, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
            draw_line(acc_x, top_y, Gosu::Color::WHITE, acc_x, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
            draw_line(acc_x+acc_width, top_y, Gosu::Color::WHITE, acc_x+acc_width, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
            #draw proportion area
            draw_rect(acc_x, acc_y, acc_width, acc_height, color, ZOrder::LAYER_1, mode=:default)
            #display percentage
            @normal_text.draw_text("#{@accuracy.percentage}%", acc_x, bottom_y, ZOrder::LAYER_2, 3.0, 3.0, color) if @accuracy.percentage < 100
            @normal_text.draw_text("#{@accuracy.percentage.to_i}%", acc_x, bottom_y, ZOrder::LAYER_2, 3.0, 3.0, color) if @accuracy.percentage == 100
        end
    end

    def show_performance(set_index)
        if !@showed_perf
            @performance = rate_performance(@sets_of_ranked_tasks[set_index], @sets_of_real_decisions[set_index])
            @showed_perf = true
        end

        @normal_text.draw_text("Performance:", 1200, 225, ZOrder::LAYER_2, 2.0, 2.0, DEFAULT_YELLOW)

        color = Gosu::Color::GREEN if @performance.percentage >= 80
        color = Gosu::Color::RED if @performance.percentage < 50
        color = Gosu::Color::YELLOW if @performance.percentage >= 50 && @performance.percentage < 80
        #draw Performance chart
        top_y, bottom_y = 300, 750
        perf_width = 150
        perf_height = (@performance.percentage / 100) * (bottom_y - top_y)
        perf_x = 1250
        perf_y = bottom_y - perf_height
        #draw border
        draw_line(perf_x, top_y, Gosu::Color::WHITE, perf_x+perf_width, top_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
        draw_line(perf_x, bottom_y, Gosu::Color::WHITE, perf_x+perf_width, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
        draw_line(perf_x, top_y, Gosu::Color::WHITE, perf_x, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
        draw_line(perf_x+perf_width, top_y, Gosu::Color::WHITE, perf_x+perf_width, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
        #draw proportion area
        draw_rect(perf_x, perf_y, perf_width, perf_height, color, ZOrder::LAYER_1, mode=:default)
        #display percentage
        @normal_text.draw_text("#{@performance.percentage}%", perf_x, bottom_y, ZOrder::LAYER_2, 3.0, 3.0, color) if @performance.percentage < 100
        @normal_text.draw_text("#{@performance.percentage.to_i}%", perf_x, bottom_y, ZOrder::LAYER_2, 3.0, 3.0, color) if @performance.percentage == 100
        #display detailed stats when hover button
        if (mouse_x > perf_x && mouse_x < perf_x+perf_width) and (mouse_y > top_y && mouse_y < bottom_y) and !@performance.nil?
            draw_rect(mouse_x, mouse_y, 300, 200, Gosu::Color::WHITE, ZOrder::LAYER_3, mode=:default)
            @normal_text.draw_text("Completed: #{@performance.completed}", mouse_x+10, mouse_y+10, ZOrder::LAYER_4, 1.0, 1.0, Gosu::Color::BLACK)
            @normal_text.draw_text("Incomplete: #{@performance.total - @performance.completed}", mouse_x+10, mouse_y+40, ZOrder::LAYER_4, 1.0, 1.0, Gosu::Color::BLACK)
            @normal_text.draw_text("Total: #{@performance.total}", mouse_x+10, mouse_y+70, ZOrder::LAYER_4, 1.0, 1.0, Gosu::Color::BLACK)
        end
    end

    def show_stats
        @label_text.draw_text("SET #{@set_indicator+1}", 750, 100, ZOrder::LAYER_1, 2.5, 2.5, DEFAULT_YELLOW)
        show_prediction(@set_indicator)
        show_reality(@set_indicator)
        show_performance(@set_indicator)
        show_accuracy(@set_indicator)
    end

    def draw_return_button
        if (mouse_x > RETURN_BUTTON_X and mouse_x < RETURN_BUTTON_X + BUTTON_WIDTH) and (mouse_y > RETURN_BUTTON_Y and mouse_y < RETURN_BUTTON_Y + BUTTON_HEIGHT)
            @screen_choice = 3 if button_down?(Gosu::MsLeft)
            draw_rect(RETURN_BUTTON_X, RETURN_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_RED, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("\u{2190} RETURN", RETURN_BUTTON_X+12, RETURN_BUTTON_Y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_YELLOW)
        else
            draw_rect(RETURN_BUTTON_X, RETURN_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, DEFAULT_YELLOW, ZOrder::LAYER_2, mode=:default)
            @button_font.draw_text("\u{2190} RETURN", RETURN_BUTTON_X+12, RETURN_BUTTON_Y+15, ZOrder::LAYER_3, 1.5, 1.5, DEFAULT_RED)
        end
    end

    def display_screen_4
        show_stats
        draw_return_button
    end

    def display_overall_performance
        if !@showed_perf
            @number_of_completed_sets.times do |i|
                @overall_performance[i] = rate_performance(@sets_of_ranked_tasks[i], @sets_of_real_decisions[i])
            end
            @showed_perf = true
        end

        @normal_text.draw_text("Overall Performance:", 750, 175, ZOrder::LAYER_2, 2.5, 2.5, DEFAULT_YELLOW)

        @number_of_completed_sets.times do |k|
            color = Gosu::Color::GREEN if @overall_performance[k].percentage >= 80
            color = Gosu::Color::RED if @overall_performance[k].percentage < 50
            color = Gosu::Color::YELLOW if @overall_performance[k].percentage >= 50 && @overall_performance[k].percentage < 80
            #draw multiple Performance charts
            top_y, bottom_y = 300, 750
            perf_width = 150
            perf_height = (@overall_performance[k].percentage / 100) * (bottom_y - top_y)
            perf_x = 75 + 200*k
            perf_y = bottom_y - perf_height
            #draw border
            draw_line(perf_x, top_y, Gosu::Color::WHITE, perf_x+perf_width, top_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
            draw_line(perf_x, bottom_y, Gosu::Color::WHITE, perf_x+perf_width, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
            draw_line(perf_x, top_y, Gosu::Color::WHITE, perf_x, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
            draw_line(perf_x+perf_width, top_y, Gosu::Color::WHITE, perf_x+perf_width, bottom_y, Gosu::Color::WHITE, ZOrder::LAYER_1)
            #draw proportion area
            draw_rect(perf_x, perf_y, perf_width, perf_height, color, ZOrder::LAYER_1, mode=:default)
            #display percentage
            @normal_text.draw_text("#{@overall_performance[k].percentage}%", perf_x, bottom_y, ZOrder::LAYER_2, 3.0, 3.0, color) if @overall_performance[k].percentage < 100
            @normal_text.draw_text("#{@overall_performance[k].percentage.to_i}%", perf_x, bottom_y, ZOrder::LAYER_2, 3.0, 3.0, color) if @overall_performance[k].percentage == 100
        end

        if @number_of_completed_sets > 1
            current = @overall_performance[@number_of_completed_sets-1].percentage
            last = @overall_performance[@number_of_completed_sets-2].percentage
            change = (current - last).abs
            @normal_text.draw_text("Your performance has", 700, 900, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::WHITE)
            @normal_text.draw_text("improved", 800, 950, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::GREEN) if current-last > 0
            @normal_text.draw_text("decreased", 800, 950, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::RED) if current-last < 0
            @normal_text.draw_text("been the same since last time", 800, 950, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::WHITE) if current-last == 0
            @normal_text.draw_text("by", 950, 950, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::WHITE) if current-last != 0
            @normal_text.draw_text("#{change}%", 1000, 950, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::GREEN) if current-last > 0
            @normal_text.draw_text("#{change}%", 1000, 950, ZOrder::LAYER_2, 1.5, 1.5, Gosu::Color::RED) if current-last < 0
        end
    end

    def display_screen_5
        display_overall_performance if @perf_choice
        draw_return_button
    end

    def draw_navigation_bar
        icon_x, icon_y = 1830, 30
        icon_width = icon_height = 70
        
        menu_x, menu_y = 1600, icon_y+icon_height+10
        menu_width, menu_height = 1920 - menu_x, 1080 - menu_y

        home_x, home_y = menu_x+75, menu_y+150
        stats_x, stats_y = home_x, home_y+400
        
        @menu_icon.draw(icon_x+5, icon_y+5, ZOrder::LAYER_2, 0.12, 0.12)
        if (mouse_x > icon_x and mouse_x < icon_x + icon_width) and (mouse_y > icon_y and mouse_y < icon_y + icon_height)
            draw_rect(icon_x, icon_y, icon_width, icon_height, DEFAULT_PURPLE, ZOrder::LAYER_1, mode=:default)
            if button_down?(Gosu::MsLeft)
                @display_menu = true
            end
        else
            @display_menu = false if button_down?(Gosu::MsLeft) and !((mouse_x > menu_x && mouse_x < menu_x + menu_width) && (mouse_y > menu_y && mouse_y < menu_y + menu_height))
            draw_rect(icon_x, icon_y, icon_width, icon_height, DEFAULT_YELLOW, ZOrder::LAYER_1, mode=:default)
        end

        if @display_menu
            draw_rect(menu_x, menu_y, menu_width, menu_height, Gosu::Color::WHITE, ZOrder::LAYER_2, mode=:default)
            #home
            @home_icon.draw(home_x, home_y, ZOrder::LAYER_3, 0.3, 0.3)
            @normal_text.draw_text("HOME", home_x+20, home_y+175, ZOrder::LAYER_3, 2.0, 2.0, Gosu::Color::BLACK)
            if (mouse_x > home_x-30 and mouse_x < home_x+185) and (mouse_y > home_y-30 and mouse_y < home_y+250)
                draw_line(home_x-30, home_y-30, DEFAULT_RED, home_x+185, home_y-30, DEFAULT_RED, ZOrder::LAYER_3)
                draw_line(home_x-30, home_y+250, DEFAULT_RED, home_x+185, home_y+250, DEFAULT_RED, ZOrder::LAYER_3)
                draw_line(home_x-30, home_y-30, DEFAULT_RED, home_x-30, home_y+250, DEFAULT_RED, ZOrder::LAYER_3)
                draw_line(home_x+185, home_y-30, DEFAULT_RED, home_x+185, home_y+250, DEFAULT_RED, ZOrder::LAYER_3)
                @screen_choice = 0 if button_down?(Gosu::MsLeft)
            end
            #stats
            @stats_icon.draw(stats_x, stats_y, ZOrder::LAYER_3, 0.3, 0.3)
            @normal_text.draw_text("STATS", stats_x+20, stats_y+175, ZOrder::LAYER_3, 2.0, 2.0, Gosu::Color::BLACK)
            if (mouse_x > stats_x-30 and mouse_x < stats_x+185) and (mouse_y > stats_y-30 and mouse_y < stats_y+250)
                draw_line(stats_x-30, stats_y-30, DEFAULT_RED, stats_x+185, stats_y-30, DEFAULT_RED, ZOrder::LAYER_3)
                draw_line(stats_x-30, stats_y+250, DEFAULT_RED, stats_x+185, stats_y+250, DEFAULT_RED, ZOrder::LAYER_3)
                draw_line(stats_x-30, stats_y-30, DEFAULT_RED, stats_x-30, stats_y+250, DEFAULT_RED, ZOrder::LAYER_3)
                draw_line(stats_x+185, stats_y-30, DEFAULT_RED, stats_x+185, stats_y+250, DEFAULT_RED, ZOrder::LAYER_3)
                @screen_choice = 3 if button_down?(Gosu::MsLeft)
            end
        end
    end

    # Modify your switch_screens method to track screen views
    def switch_screens
        case @screen_choice
        when 0
            display_home_screen
            draw_navigation_bar
            @metrics&.track_screen_view('home')
        when 1
            display_screen_1
            @metrics&.track_screen_view('create_tasks')
        when 2
            display_screen_2
            @metrics&.track_screen_view('arranged_tasks')
        when 3
            display_screen_3
            draw_navigation_bar
            @metrics&.track_screen_view('saved_sets')
        when 4
            display_screen_4
            @metrics&.track_screen_view('set_details')
        when 5
            display_screen_5
            @metrics&.track_screen_view('performance')
        end        
    end

    def draw_background
        @background.draw(0, 0, ZOrder::BACKGROUND, 1, 1, Gosu::Color.new(170, 170, 170 , 170))
    end

#--------------------------------------------------Interact section------------------------------------------------
    def button_down(id)
        case id
        when Gosu::KB_LEFT_CONTROL
            self.fullscreen = true
        when Gosu::KB_ESCAPE
            if self.fullscreen?
                self.fullscreen = false
            end
                
        when Gosu::MsLeft
            self.text_input = @text_fields.find { |tf| tf.under_point?(mouse_x, mouse_y) }
            self.text_input.move_caret(mouse_x) unless self.text_input.nil?

        when Gosu::KbReturn #Enter key pressed
            if self.text_input
                # Assign the text input to a variable
                @description = self.text_input.text
            end
        end
      
    end

    # Modify save button click to track metrics
    def mouse_clicked_save_button
        if ((mouse_x > SAVE_BUTTON_X and mouse_x < SAVE_BUTTON_X + BUTTON_WIDTH) and (mouse_y > SAVE_BUTTON_Y and mouse_y < SAVE_BUTTON_Y + BUTTON_HEIGHT) and button_down?(Gosu::MsLeft))
            @metrics&.track_button_click('save')
            # Track successful task creation
            if !@save_clicked && !@duplicate_warning && !@not_entered_warning && !@not_enough_attributes_warning && @i < 10
                @metrics&.track_task_created(@set_index)
            end
            return true
        else
            false
        end
    end

    def mouse_clicked_confirm_button
        if ((mouse_x > CONFIRM_BUTTON_X and mouse_x < CONFIRM_BUTTON_X + BUTTON_WIDTH) and (mouse_y > CONFIRM_BUTTON_Y and mouse_y < CONFIRM_BUTTON_Y + BUTTON_HEIGHT) and button_down?(Gosu::MsLeft))
          true
        else
          false
        end
    end

    def draw
        draw_background
        switch_screens
    end

    # Track errors
    def update
        super
    rescue => e
        @metrics&.track_error('runtime_error', e.message)
        raise e
    end
end

AutoTaskArrangement.new.show