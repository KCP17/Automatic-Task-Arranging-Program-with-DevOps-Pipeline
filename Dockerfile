FROM ruby:3.1

# Set working directory
WORKDIR /app

# Copy all project files
COPY AutomaticTaskArranging.rb .
COPY background.jpg .
COPY balloon_chat.png .
COPY Baloo-Regular.ttf .
COPY checkmark.png .
COPY ClassificationSystem.rb .
COPY ClassificationSystem.py .
COPY color_palette.png .
COPY EvaluationSystem.rb .
COPY home_icon.png .
COPY menu_icon.png .
COPY stats_icon.png .
COPY TextInput.rb .

# Install required gems
RUN gem install gosu
RUN gem install decisiontree

# Expose container port
EXPOSE 3000

# Command to run the application
CMD ["ruby", "AutomaticTaskArranging.rb"]