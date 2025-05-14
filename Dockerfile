FROM ruby:3.1

# Install SDL2 and audio dependencies
RUN apt-get update && apt-get install -y \
    libsdl2-dev \
    libsdl2-ttf-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libogg-dev \
    libvorbis-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy all project files
COPY AutomaticTaskArranging.rb .
COPY background.jpg .
COPY balloon_chat.png .
COPY Baloo-Regular.ttf .
COPY checkmark.png .
COPY ClassificationSystem.rb .
COPY color_palette.png .
COPY EvaluationSystem.rb .
COPY home_icon.png .
COPY menu_icon.png .
COPY stats_icon.png .
COPY TextInput.rb .

# Copy test files
COPY test/ ./test/
COPY spec/ ./spec/
COPY run_tests.rb .

# Install required gems
RUN gem install gosu
RUN gem install decisiontree
RUN gem install minitest
RUN gem install rspec

# Expose container port
EXPOSE 3000

# Command to run the application
CMD ["ruby", "AutomaticTaskArranging.rb"]