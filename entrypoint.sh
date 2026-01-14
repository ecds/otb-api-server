#!/bin/bash
/usr/local/bin/bundle exec rake db:migrate

bundle exec puma -C config/puma.rb
