#!/bin/bash

./scripts/generate.rsa.sh
./scripts/karafka.web.sh

rm -f ./tmp/pids/server.pid
bundle install

# DO NOT run migrations here - they will be handled by a separate migrate service
# This prevents race conditions between multiple API containers

# Only seed organization if migrations are already done
if bundle exec rails runner "ActiveRecord::Migration.check_pending!" 2>/dev/null; then
  bundle exec rails signup:seed_organization
fi

rails s -b 0.0.0.0
