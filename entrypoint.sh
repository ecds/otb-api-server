#!/bin/bash
/usr/local/bin/bundle exec rake db:migrate
/usr/local/bin/bundle exec sidekiq&
bundle exec puma -C config/puma.rb
