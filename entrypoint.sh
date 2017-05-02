#!/usr/bin/env bash
set -e

# Treat every docker start as an update.
cd /app

rake db:migrate
rake db:mongoid:remove_undefined_indexes
rake db:mongoid:create_indexes
rake assets:precompile
bundle exec puma -C config/puma.default.rb

exec "$@"
