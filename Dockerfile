FROM ruby:2.7

# Install dependencies
RUN apt-get update && apt-get install -y \
    libsdl2-dev \
    libsdl2-ttf-dev \
    libpango1.0-dev \
    libgl1-mesa-dev \
    libopenal-dev \
    libsndfile-dev \
    libgmp-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy files
COPY . .

# Install gems
RUN gem install bundler && bundle install

# Copy resources (make sure these files exist in your repository)
RUN mkdir -p /app/resources
COPY *.jpg /app/resources/ || true
COPY *.png /app/resources/ || true
COPY *.ttf /app/resources/ || true

EXPOSE 4567

CMD ["ruby", "AutomaticTaskArranging.rb"]