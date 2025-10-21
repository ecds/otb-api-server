FROM ruby:3.1.2-slim

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