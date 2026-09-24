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

WORKDIR /rails

COPY Gemfile Gemfile.lock ./

RUN gem install bundler:2.3.7
RUN bundle install

COPY . .

RUN mkdir -p /data/tmp public/storage/tmp tmp/pids

EXPOSE 3000

RUN chmod +x ./entrypoint.sh

# Run as a non-root user rather than the default root. Nothing entrypoint.sh
# does (migrations, sidekiq, puma on the unprivileged port 3000) needs root
# at runtime. UID/GID are fixed rather than auto-assigned so ownership is
# consistent across rebuilds.
RUN groupadd --gid 1000 rails && \
    useradd --uid 1000 --gid rails --create-home --shell /bin/bash rails && \
    chown -R rails:rails /rails /data/tmp

USER rails

ENTRYPOINT ["./entrypoint.sh"]