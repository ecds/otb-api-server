#!/bin/bash
/usr/local/bin/bundle exec rake db:migrate
/usr/local/bin/bundle exec sidekiq&
/usr/local/bin/bundle exec rake searchkick:reindex CLASS=User
bundle exec puma -C config/puma.rb
