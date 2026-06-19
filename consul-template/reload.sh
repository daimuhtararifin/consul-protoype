#!/bin/sh
set -eu

kind="${1:?reload kind is required}"
target="${2:?target container is required}"

is_running() {
  [ "$(docker inspect -f '{{.State.Running}}' "$target" 2>/dev/null || true)" = "true" ]
}

case "$kind" in
  app)
    if is_running; then
      echo "Restarting ${target} after config render..."
      docker restart "$target"
    else
      echo "Skipping restart for ${target}; container is not running yet."
    fi
    ;;
  nginx)
    if is_running; then
      echo "Reloading ${target} after nginx config render..."
      docker kill --signal=HUP "$target"
    else
      echo "Skipping reload for ${target}; container is not running yet."
    fi
    ;;
  *)
    echo "Unknown reload kind: ${kind}" >&2
    exit 1
    ;;
esac