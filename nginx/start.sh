#!/bin/sh
set -eu

CONFIG_FILE="${NGINX_CONFIG_FILE:-/generated/nginx.conf}"

echo "Waiting for nginx config: ${CONFIG_FILE}"
while [ ! -f "$CONFIG_FILE" ]; do
  sleep 1
done

echo "Starting nginx with rendered config..."
exec nginx -c "$CONFIG_FILE" -g "daemon off;"