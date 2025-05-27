#!/bin/bash
# =============================================================================
# DEVELOPMENT DATABASE MIGRATION SCRIPT
# =============================================================================
# 
# This script safely handles database migrations in development environment.
# It prevents race conditions by running migrations in a single dedicated
# container before starting any API services.
#
# =============================================================================

set -euo pipefail

echo "🗃️  Starting database migration for development environment..."

# Wait for database to be ready
echo "⏳ Waiting for database connection..."
timeout=60
elapsed=0

while [ $elapsed -lt $timeout ]; do
  if pg_isready -h db -p 5432 -U ${POSTGRES_USER:-lago} -d postgres; then
    echo "✅ Database connection established"
    break
  fi
  echo "   Waiting for database... (${elapsed}s/${timeout}s)"
  sleep 2
  elapsed=$((elapsed + 2))
done

if [ $elapsed -ge $timeout ]; then
  echo "❌ Database connection timeout after ${timeout}s"
  exit 1
fi

# Check if database exists, create if needed
echo "🔍 Checking if lago database exists..."
if ! psql -h db -U ${POSTGRES_USER:-lago} -d postgres -lqt | cut -d \| -f 1 | grep -qw lago; then
  echo "📝 Creating lago database..."
  createdb -h db -U ${POSTGRES_USER:-lago} lago
  echo "✅ Database created successfully"
else
  echo "✅ Database already exists"
fi

# Check current migration status
echo "🔍 Checking migration status..."
pending_count=$(bundle exec rails db:migrate:status 2>/dev/null | grep "^\s*down" | wc -l || echo "unknown")

if [ "$pending_count" = "unknown" ]; then
  echo "📝 Database appears to be uninitialized, running setup..."
  bundle exec rails db:setup
else
  echo "📊 Found $pending_count pending migrations"
  if [ "$pending_count" -gt 0 ]; then
    echo "📝 Running pending migrations..."
    bundle exec rails db:migrate
  else
    echo "✅ All migrations are up to date"
  fi
fi

# Seed organization if needed
echo "🌱 Setting up organization..."
bundle exec rails signup:seed_organization

echo "🎉 Database migration completed successfully!"
