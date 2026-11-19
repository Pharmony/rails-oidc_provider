#!/usr/bin/env bash
set -euo pipefail

cd /app
bundle check >/dev/null 2>&1 || bundle install

mkdir -p spec/dummy/db spec/dummy/lib spec/dummy/log spec/dummy/tmp

export RAILS_ENV="${RAILS_ENV:-test}"
export APP_HOST="${APP_HOST:-www.example.com}"
export OIDC_PROVIDER_KEY_PASSPHRASE="${OIDC_PROVIDER_KEY_PASSPHRASE:-test-passphrase}"

cd /app/spec/dummy

if [ ! -f lib/oidc_provider_key.pem ]; then
  cd /app
  bundle exec rake app:oidc_provider:generate_key
  cd /app/spec/dummy
fi

bundle exec rails db:drop db:create db:migrate

cd /app
exec "$@"
