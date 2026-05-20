#!/usr/bin/env bash
set -euo pipefail

WATCH_DIR=/project/content/tex
POLL_INTERVAL=2
SENTINEL=/tmp/.last_build

touch "$SENTINEL"
echo "Watcher: polling $WATCH_DIR for .tex changes every ${POLL_INTERVAL}s..."

while true; do
  sleep "$POLL_INTERVAL"
  if find "$WATCH_DIR" -name '*.tex' -newer "$SENTINEL" | grep -q .; then
    echo "Watcher: change detected, rebuilding..."
    if /app/build.sh; then
      echo "Watcher: rebuild complete — refresh your browser"
    else
      echo "Watcher: rebuild failed, check output above"
    fi
    touch "$SENTINEL"
  fi
done
