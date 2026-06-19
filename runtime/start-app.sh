#!/bin/sh
set -eu

CONFIG_FILE="${CONFIG_FILE:-/config/config.env}"

echo "Waiting for app config: ${CONFIG_FILE}"
while [ ! -f "$CONFIG_FILE" ]; do
  sleep 1
done

set -a
. "$CONFIG_FILE"
set +a

exec "$@"