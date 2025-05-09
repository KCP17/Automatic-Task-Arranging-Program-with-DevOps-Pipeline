FROM ruby:3.0

# Install dependencies for Gosu
RUN apt-get update && apt-get install -y \
    build-essential \
    libsdl2-dev \
    libsdl2-ttf-dev \
    libpango1.0-dev \
    libgl1-mesa-dev \
    libopenal-dev \
    libsndfile-dev \
    libgmp-dev

# Set working directory
WORKDIR /app

# Copy gem specifications first
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

# Copy application code
COPY . .

# Set display variable for Gosu (headless mode)
ENV DISPLAY=:0

# Command to run the application
CMD ["ruby", "AutomaticTaskArranging.rb"]