FROM ruby:3.1

# Set working directory
WORKDIR /app

# Install SDL2 and audio dependencies
RUN apt-get update && apt-get install -y \
    libsdl2-dev \
    libsdl2-ttf-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libogg-dev \
    libvorbis-dev \
    && rm -rf /var/lib/apt/lists/*

# Install SonarScanner
RUN apt-get update && apt-get install -y wget unzip default-jre && \
    wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.7.0.2747-linux.zip && \
    unzip sonar-scanner-cli-4.7.0.2747-linux.zip && \
    mv sonar-scanner-4.7.0.2747-linux /opt/sonar-scanner && \
    ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm sonar-scanner-cli-4.7.0.2747-linux.zip

# Install Xvfb and X11 dependencies
RUN apt-get update && apt-get install -y \
    xvfb \
    libx11-6 \
    x11-utils \
    xfonts-base \
    && rm -rf /var/lib/apt/lists/*

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

# Copy sonar properties file
COPY sonar-project.properties .

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Copy Prometheus metrics file (monitoring)
# COPY prometheus_metrics.rb .

# Install required gems
RUN gem install gosu
RUN gem install decisiontree

# Install gems for testing
RUN gem install minitest
RUN gem install rspec

# Install bundler-audit for security scanning
RUN gem install bundler-audit && \
    bundle-audit update

# Add new gems for Prometheus and WEBrick
# RUN gem install prometheus-client
# RUN gem install webrick

# Expose container port
EXPOSE 3000

# Create a startup script that works in the container (this is Windows-friendly)
RUN echo '#!/bin/bash\nXvfb :99 -screen 0 1024x768x16 -ac &\nexport DISPLAY=:99\nsleep 1\nexec ruby /app/AutomaticTaskArranging.rb' > /app/start.sh \
    && chmod +x /app/start.sh

# Set the start script as the container's entry point
CMD ["/bin/bash", "/app/start.sh"]