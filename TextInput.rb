require 'gosu'
class TextField < Gosu::TextInput
    INACTIVE_COLOR = Gosu::Color.rgb(80,80,80)
    ACTIVE_COLOR = Gosu::Color.rgb(177,72,210)
    CARET_COLOR = Gosu::Color::WHITE
    PADDING = 5

    attr_reader :x_coordinate, :y_coordinate

    def initialize(window, font, x_coordinate, y_coordinate, prompt)
        super()
        @window, @font, @x_coordinate, @y_coordinate, @prompt = window, font, x_coordinate, y_coordinate, prompt
        self.text = prompt
    end

    def filter(new_text)
        new_text.upcase
    end

    def draw
        if @window.text_input == self
            holder_color = ACTIVE_COLOR
        else
            holder_color = INACTIVE_COLOR
        end
      
        @window.draw_quad(x_coordinate - PADDING, y_coordinate - PADDING, holder_color, x_coordinate + width + PADDING, y_coordinate - PADDING, holder_color, x_coordinate - PADDING, y_coordinate + height + PADDING, holder_color, x_coordinate + width + PADDING, y_coordinate + height + PADDING, holder_color, 0)
        position_x = x_coordinate + @font.text_width(self.text[0...self.caret_pos])
        
        if @window.text_input == self
            @window.draw_line(position_x, y_coordinate, CARET_COLOR, position_x, y_coordinate + height, CARET_COLOR, 0)
        end
        @font.draw_text(self.text, x_coordinate, y_coordinate, 0)
    end

    def width
        @font.text_width(self.text)
    end
      
    def height
        @font.height
    end
    
    def under_point?(mouse_x, mouse_y)
        mouse_x > (x_coordinate - PADDING) and mouse_x < (x_coordinate + width + PADDING) and mouse_y > (y_coordinate - PADDING) and mouse_y < (y_coordinate + height + PADDING)
    end
    
    def move_caret(mouse_x)
        1.upto(self.text.length) do |i|
          if mouse_x < x_coordinate + @font.text_width(text[0...i])
            self.caret_pos = self.selection_start = i - 1;
            return
          end
        end
        self.caret_pos = self.selection_start = self.text.length
    end
end