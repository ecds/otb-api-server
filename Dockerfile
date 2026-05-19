FROM ruby:3.4.4-slim

ENV RAILS_ENV=production

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
    libyaml-dev \
    pkg-config \
    vim \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get install -y --fix-broken ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

COPY Gemfile Gemfile.lock ./

RUN gem install bundler:2.2.22
RUN bundle install

COPY . .

RUN mkdir -p /data/tmp public/storage/tmp tmp/pids && \
    chmod 777 /data/tmp public/storage/tmp tmp/pids

EXPOSE 3000

RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]