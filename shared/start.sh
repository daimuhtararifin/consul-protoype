#!/bin/sh
set -a
. /app/config.env
set +a
exec "$@"