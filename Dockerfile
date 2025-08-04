# Dockerfile for OpenTourBuilder API
FROM ruby:3.1.2-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      git \
      postgresql-client \
      libpq-dev \
      libgdal-dev \
      gdal-bin \
      imagemagick \
      libmagickwand-dev \
      libvips \
      pkg-config \
      && rm -rf /var/lib/apt/lists/*

# Skip Chrome for now - we can add it later if needed for testing
# The Rails app will work fine without Chrome for basic API functionality

# Set working directory
WORKDIR /rails

# Copy Gemfile first for better layer caching
COPY Gemfile Gemfile.lock ./

# Install bundler and gems
RUN gem install bundler:2.2.22
RUN bundle install

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /data/tmp public/storage/tmp tmp/pids && \
    chmod 777 /data/tmp public/storage/tmp tmp/pids

# Expose port
EXPOSE 3000

# Default command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]