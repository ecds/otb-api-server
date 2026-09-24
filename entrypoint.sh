#!/bin/bash
bundle exec rake db:migrate
bundle exec sidekiq&
bundle exec rake searchkick:reindex CLASS=User
bundle exec puma -C config/puma.rb
