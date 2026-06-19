#!/bin/sh
set -eu

until consul kv put health/check ready >/dev/null 2>&1; do
  echo "Waiting for Consul..."
  sleep 2
done

consul kv delete health/check >/dev/null

echo "Seeding Consul KV Store..."

consul kv put config/prod/shared/TZ "Asia/Jakarta"
consul kv put config/prod/shared/LOG_FORMAT "json"
consul kv put config/prod/shared/CONFIG_VERSION "v1"

consul kv put config/prod/go-app/APP_NAME "go-app"
consul kv put config/prod/go-app/APP_PORT "8001"
consul kv put config/prod/go-app/LOG_LEVEL "debug"

consul kv put config/prod/cpp-app/APP_NAME "cpp-app"
consul kv put config/prod/cpp-app/APP_PORT "8002"
consul kv put config/prod/cpp-app/LOG_LEVEL "info"

consul kv put config/prod/java-app/APP_NAME "java-app"
consul kv put config/prod/java-app/APP_PORT "8003"
consul kv put config/prod/java-app/LOG_LEVEL "warn"

consul kv put config/prod/js-app/APP_NAME "js-app"
consul kv put config/prod/js-app/APP_PORT "8004"
consul kv put config/prod/js-app/LOG_LEVEL "debug"

consul kv put config/prod/nginx/domain "prototype.local"
consul kv put config/prod/nginx/routes/go-app "go-app:8001"
consul kv put config/prod/nginx/routes/cpp-app "cpp-app:8002"
consul kv put config/prod/nginx/routes/java-app "java-app:8003"
consul kv put config/prod/nginx/routes/js-app "js-app:8004"

echo "Seeding complete."
consul kv get -recurse config/prod/