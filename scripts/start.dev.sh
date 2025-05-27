#!/bin/bash

./scripts/generate.rsa.sh
./scripts/karafka.web.sh

rm -f ./tmp/pids/server.pid
bundle install

# Wait for database to be ready
echo "Waiting for database connection..."
timeout=60
elapsed=0

while [ $elapsed -lt $timeout ]; do
  if pg_isready -h db -p 5432 -U ${POSTGRES_USER:-lago} -d postgres; then
    echo "Database connection established"
    break
  fi
  echo "Waiting for database... (${elapsed}s/${timeout}s)"
  sleep 2
  elapsed=$((elapsed + 2))
done

if [ $elapsed -ge $timeout ]; then
  echo "ERROR: Database connection timeout after ${timeout}s"
  exit 1
fi

# Handle database setup and migrations
echo "Checking database status..."
if ! PGPASSWORD=${POSTGRES_PASSWORD:-changeme} psql -h db -U ${POSTGRES_USER:-lago} -d postgres -lqt | cut -d \| -f 1 | grep -qw lago; then
  echo "Creating lago database..."
  PGPASSWORD=${POSTGRES_PASSWORD:-changeme} createdb -h db -U ${POSTGRES_USER:-lago} lago
fi

# Run migrations
echo "Running database migrations..."
bundle exec rails db:migrate

# Seed organization
echo "Seeding organization..."
bundle exec rails signup:seed_organization

echo "Starting Rails server..."
rails s -b 0.0.0.0
